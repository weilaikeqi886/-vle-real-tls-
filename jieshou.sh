#!/bin/bash
# 接收端一键配置脚本 (增强版：支持多文件分目录存储)

# 1. 安装基础依赖
apt update && apt install python3 python3-pip -y

# 2. 创建存储主目录
mkdir -p /root/uploaded_results

# 3. 编写增强版接收程序
cat << 'EOF' > /root/receiver.py
from flask import Flask, request
import os
from datetime import datetime

app = Flask(__name__)
# 基础存储目录
BASE_UPLOAD_FOLDER = '/root/uploaded_results'

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return "No file part", 400
    
    file = request.files['file']
    if file.filename == '':
        return "No selected file", 400
    
    # 获取发送者 IP 和 当前日期（精确到分，方便将同一批次的文件归类）
    sender_ip = request.remote_addr
    # 使用 YYYYMMDD_HHMM 格式，同一分钟内的上传会进同一个文件夹
    # 如果你希望极度精确，可以包含秒，但同一批次的两个文件可能会分到两个文件夹
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    
    # 文件夹名称：时间_IP
    folder_name = f"{timestamp}_{sender_ip}"
    target_dir = os.path.join(BASE_UPLOAD_FOLDER, folder_name)
    
    # 自动创建文件夹
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)
    
    # 保存文件（保持原始文件名：all_links.txt 或 hosts.ini）
    save_path = os.path.join(target_dir, file.filename)
    file.save(save_path)
    
    print(f"[*] 收到文件: {file.filename} | 来自: {sender_ip} | 存至: {folder_name}")
    return f"Success: {file.filename} uploaded to {folder_name}", 200

if __name__ == '__main__':
    # 运行在 5000 端口
    app.run(host='0.0.0.0', port=5000)
EOF

# 4. 安装 Flask (适配 PEP 668)
pip3 install flask --break-system-packages || pip3 install flask

# 5. 创建 Systemd 服务保持后台运行
cat << 'EOF' > /etc/systemd/system/link_receiver.service
[Unit]
Description=Link and Hosts File Receiver
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/receiver.py
Restart=always
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

# 6. 启动服务
systemctl daemon-reload
systemctl enable link_receiver
systemctl restart link_receiver

echo -e "\033[0;32m==================================================\033[0m"
echo -e "\033[0;32m接收端配置完成！\033[0m"
echo -e "服务运行端口: \033[1;33m5000\033[0m"
echo -e "所有文件将分类存放在: \033[1;36m/root/uploaded_results/\033[0m"
echo -e "目录结构示例: /root/uploaded_results/20260120_1405_1.2.3.4/all_links.txt"
echo -e "\033[0;32m==================================================\033[0m"
