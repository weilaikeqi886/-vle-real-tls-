#!/bin/bash

# 定义颜色
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PLAIN='\033[0m'

clear
echo -e "${BLUE}==================================================${PLAIN}"
echo -e "${BLUE}       REALITY 1000台服务器批量部署环境初始化       ${PLAIN}"
echo -e "${BLUE}==================================================${PLAIN}"

# 1. 安装基础依赖
echo -e "${YELLOW}正在安装 Ansible 及必要组件...${PLAIN}"
apt update && apt install ansible sshpass python3 curl -y

# 2. 创建目录结构
WORKDIR="reality_batch"
mkdir -p ~/${WORKDIR}/results
cd ~/${WORKDIR}

# 3. 写入修正后的 deploy.yml
cat << 'EOF' > deploy.yml
---
- name: 1000台服务器 REALITY 全自动部署
  hosts: nodes
  gather_facts: no

  vars_prompt:
    - name: "listen_port"
      prompt: "请输入想要在哪个端口上部署？(直接回车默认443)"
      default: "443"
      private: no

  vars:
    dest_domain: "dl.google.com"

  tasks:
    - name: 1. [本地] 动态生成 Xray 模板
      delegate_to: localhost
      run_once: true
      copy:
        dest: "./xray.conf.j2"
        content: |
          {
              "log": { "loglevel": "warning" },
              "inbounds": [{
                  "port": {{ listen_port }},
                  "protocol": "vless",
                  "settings": {
                      "clients": [{"id": "{{ "{{ my_uuid }}" }}", "flow": "xtls-rprx-vision"}],
                      "decryption": "none"
                  },
                  "streamSettings": {
                      "network": "tcp",
                      "security": "reality",
                      "realitySettings": {
                          "show": false,
                          "dest": "{{ dest_domain }}:443",
                          "xver": 0,
                          "serverNames": ["{{ dest_domain }}"],
                          "privateKey": "{{ "{{ priv_key }}" }}",
                          "shortIds": ["6a2b3c4d"]
                      }
                  }
              }],
              "outbounds": [{ "protocol": "freedom" }]
          }

    - name: 2. [被控机] 环境修复与粒子云网页部署
      shell: |
        apt-get update && apt-get install -y curl ntpdate nginx
        ntpdate -u pool.ntp.org || true
        iptables -P INPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables -P OUTPUT ACCEPT
        iptables -F && iptables -X
        rm -f /etc/nginx/sites-enabled/default
        cat << 'HTML' > /var/www/html/index.html
        <!DOCTYPE html><html><head><meta charset="utf-8"><title>Welcome</title><style>body{margin:0;overflow:hidden;background:#000}canvas{display:block}</style></head><body><canvas id="canvas"></canvas><script>const canvas=document.getElementById("canvas"),ctx=canvas.getContext("2d");let w,h,particles=[];function init(){w=canvas.width=window.innerWidth;h=canvas.height=window.innerHeight;particles=[];for(let i=0;i<100;i++)particles.push({x:Math.random()*w,y:Math.random()*h,vx:Math.random()-.5,vy:Math.random()-.5})}function draw(){ctx.fillStyle="rgba(0,0,0,0.1)";ctx.fillRect(0,0,w,h);ctx.fillStyle="#00FF00";particles.forEach(p=>{p.x+=p.vx;p.y+=p.vy;if(p.x<0||p.x>w)p.vx*=-1;if(p.y<0||p.y>h)p.vy*=-1;ctx.beginPath();ctx.arc(p.x,p.y,1.5,0,Math.PI*2);ctx.fill()});requestAnimationFrame(draw)}window.onresize=init;init();draw();</script></body></html>
        HTML
        chmod -R 755 /var/www/html
        systemctl restart nginx && systemctl enable nginx
      ignore_errors: yes

    - name: 3. [被控机] 安装 Xray 并生成密钥
      shell: |
        if [ ! -f "/usr/local/bin/xray" ]; then
          curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash -s -- install
        fi
        /usr/local/bin/xray x25519
      register: key_output

    - name: 4. [被控机] 提取变量
      set_fact:
        priv_key: "{{ key_output.stdout_lines[0].split(': ')[1] | trim }}"
        pub_key: "{{ key_output.stdout_lines[1].split(': ')[1] | trim }}"
        my_uuid: "{{ lookup('password', '/dev/null length=36 chars=ascii_letters') | to_uuid }}"

    - name: 5. [被控机] 下发配置并启动 Xray
      template:
        src: "./xray.conf.j2"
        dest: /usr/local/etc/xray/config.json

    - name: 6. [被控机] 内核 BBR 优化
      shell: |
        systemctl enable xray && systemctl restart xray
        if ! grep -q "bbr" /etc/sysctl.conf; then
          echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
          echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
          sysctl -p
        fi
      ignore_errors: yes

    - name: 7. [回收] 写入凭据并回传控制机
      shell: |
        echo "ip={{ inventory_hostname }},uuid={{ my_uuid }},pub={{ pub_key }},port={{ listen_port }}" > /tmp/node_info.txt
      changed_when: false

    - name: 8. [回收] 执行拉取
      fetch:
        src: /tmp/node_info.txt
        dest: "./results/{{ inventory_hostname }}.txt"
        flat: yes

    - name: 9. [本地] 自动汇总订阅链接
      delegate_to: localhost
      run_once: true
      shell: |
        cat << 'PY' > gen_links.py
        import os, urllib.parse, base64
        links = []
        res_dir = './results'
        if os.path.exists(res_dir):
            for f in os.listdir(res_dir):
                if f.endswith('.txt'):
                    with open(os.path.join(res_dir, f), 'r') as file:
                        c = file.read().strip()
                        if c:
                            try:
                                d = dict(x.split('=') for x in c.split(','))
                                p = {"encryption":"none","flow":"xtls-rprx-vision","security":"reality","sni":"{{ dest_domain }}","fp":"chrome","pbk":d['pub'],"sid":"6a2b3c4d","type":"tcp"}
                                url = f"vless://{d['uuid']}@{d['ip']}:{d['port']}?{urllib.parse.urlencode(p)}#Reality_{d['ip']}"
                                links.append(url)
                            except: pass
            with open('all_links.txt', 'w') as f: f.write('\n'.join(links))
            with open('subscribe.txt', 'w') as f: f.write(base64.b64encode('\n'.join(links).encode()).decode())
        PY
        python3 gen_links.py
      args:
        executable: /bin/bash
EOF

# 4. 生成 hosts.ini 模板
cat << 'EOF' > hosts.ini
[nodes]
# 格式示例：8.8.8.8 ansible_port=22 ansible_ssh_pass="你的密码"

[nodes:vars]
ansible_ssh_user=root
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=15'
EOF

# 5. 打印指引
chmod +x deploy.yml 2>/dev/null # 预防万一
echo -e "${GREEN}==================================================${PLAIN}"
echo -e "${GREEN}         ✅ 环境初始化完成！${PLAIN}"
echo -e "${GREEN}==================================================${PLAIN}"
echo -e "${YELLOW}接下来的正确操作步骤：${PLAIN}"
echo -e "${BLUE}1. 进入目录：${PLAIN} cd ~/reality_batch"
echo -e "${BLUE}2. 填入IP：${PLAIN}  nano hosts.ini"
echo -e "${BLUE}3. 执行部署：${PLAIN} cd ~/reality_batch && ansible-playbook -i hosts.ini deploy.yml -f 30"
