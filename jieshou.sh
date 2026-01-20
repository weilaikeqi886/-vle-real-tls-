#!/bin/bash
# 接收端一键配置脚本

# 1. 安装依赖
apt update && apt install python3 python3-pip -y

# 2. 创建存储目录
mkdir -p /root/uploaded_links

# 3. 编写接收程序
cat << 'EOF' > /root/receiver.py
from flask import Flask, request
import os
from datetime import datetime

app = Flask(__name__)
UPLOAD_FOLDER = '/root/uploaded_links'

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return "No file part", 400
    file = request.files['file']
    if file.filename == '':
        return "No selected file", 400
    
    # 获取发送者 IP
    sender_ip = request.remote_addr
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # 重命名文件：时间_IP_文件名
    filename = f"{timestamp}_{sender_ip}_all_links.txt"
    file.save(os.path.join(UPLOAD_FOLDER, filename))
    
    print(f"[*] 收到来自 {sender_ip} 的上传，保存为 {filename}")
    return f"Upload Success from {sender_ip}", 200

if __name__ == '__main__':
    # 运行在 5000 端口
    app.run(host='0.0.0.0', port=5000)
EOF

# 4. 安装 Flask
pip3 install flask --break-system-packages || pip3 install flask

# 5. 创建 Systemd 服务保持后台运行
cat << 'EOF' > /etc/systemd/system/link_receiver.service
[Unit]
Description=Link File Receiver
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/receiver.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 6. 启动服务
systemctl daemon-reload
systemctl enable link_receiver
systemctl start link_receiver

echo "=================================================="
echo "接收端配置完成！"
echo "服务运行端口: 5000"
echo "文件保存目录: /root/uploaded_links"
echo "=================================================="
