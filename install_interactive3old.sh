#!/bin/bash

# 定义颜色
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export PLAIN='\033[0m'

clear
echo -e "${BLUE}==================================================${PLAIN}"
echo -e "${BLUE}       REALITY 1000台全自动部署 (重试增强版)        ${PLAIN}"
echo -e "${BLUE}==================================================${PLAIN}"

# 1. 自动安装基础依赖并创建目录
echo -e "${YELLOW}正在配置本地环境与依赖...${PLAIN}"
apt update && apt install ansible sshpass python3 curl -y > /dev/null 2>&1

WORKDIR="/root/reality_batch"
mkdir -p ${WORKDIR}/results
cd ${WORKDIR}

# 2. 写入 deploy.yml (按要求生成完整版)
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

    - name: 2. [被控机] 环境修复与炫彩交互粒子云部署
      shell: |
        apt-get update && apt-get install -y curl ntpdate nginx
        ntpdate -u pool.ntp.org || true
        iptables -P INPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables -P OUTPUT ACCEPT
        iptables -F && iptables -X
        rm -f /etc/nginx/sites-enabled/default
        cat << 'HTML' > /var/www/html/index.html
        <!DOCTYPE html><html><head><meta charset="utf-8"><title>Node Active</title>
        <style>body{margin:0;overflow:hidden;background:#050505}canvas{display:block}</style></head>
        <body><canvas id="c"></canvas><script>
        const canvas=document.getElementById("c"),ctx=canvas.getContext("2d");
        let w,h,particles=[],mouse={x:null,y:null,radius:150};
        function init(){w=canvas.width=window.innerWidth;h=canvas.height=window.innerHeight;particles=[];
        for(let i=0;i<200;i++)particles.push(new Particle())}
        class Particle{constructor(){this.x=Math.random()*w;this.y=Math.random()*h;
        this.size=Math.random()*2+1;this.color="hsla("+Math.random()*360+",70%,60%,0.8)";
        this.baseX=this.x;this.baseY=this.y;this.density=(Math.random()*30)+1}
        draw(){ctx.fillStyle=this.color;ctx.beginPath();ctx.arc(this.x,this.y,this.size,0,Math.PI*2);ctx.fill()}
        update(){let dx=mouse.x-this.x,dy=mouse.y-this.y,dist=Math.sqrt(dx*dx+dy*dy);
        let forceDirectionX=dx/dist,forceDirectionY=dy/dist,maxDist=mouse.radius,force=(maxDist-dist)/maxDist;
        let directionX=forceDirectionX*force*this.density,directionY=forceDirectionY*force*this.density;
        if(dist<mouse.radius){this.x-=directionX;this.y-=directionY}else{
        if(this.x!==this.baseX){let dx=this.x-this.baseX;this.x-=dx/10}
        if(this.y!==this.baseY){let dy=this.y-this.baseY;this.y-=dy/10}}}}
        function animate(){ctx.clearRect(0,0,w,h);particles.forEach(p=>{p.update();p.draw()});requestAnimationFrame(animate)}
        window.addEventListener("mousemove",e=>{mouse.x=e.x;mouse.y=e.y});
        window.addEventListener("mouseout",()=>{mouse.x=undefined;mouse.y=undefined});
        window.onresize=init;init();animate();</script></body></html>
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
      args:
        executable: python3
EOF

# 3. 交互录入逻辑
echo -e "${YELLOW}现在开始录入服务器。全部完成后，在 [IP地址] 处直接回车开始部署。${PLAIN}"
cat << 'EOF' > hosts.ini
[nodes]
EOF

COUNT=1
while true; do
    echo -e "\n${BLUE}--- 服务器 #$COUNT ---${PLAIN}"
    read -p "IP 地址: " V_IP
    if [[ -z "$V_IP" ]]; then break; fi
    read -p "SSH 端口 (22): " V_PORT
    V_PORT=${V_PORT:-22}
    read -p "SSH 用户 (root): " V_USER
    V_USER=${V_USER:-root}
    read -p "SSH 密码: " V_PASS
    if [[ -z "$V_PASS" ]]; then echo -e "${RED}跳过：密码必填${PLAIN}"; continue; fi

    echo "$V_IP ansible_port=$V_PORT ansible_ssh_user=$V_USER ansible_ssh_pass=\"$V_PASS\" input_order=$COUNT" >> hosts.ini
    let COUNT++
done

cat << 'EOF' >> hosts.ini
[nodes:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=15'
EOF

# 4. 核心部署与重试函数
function run_deployment() {
    local INI_FILE=$1
    echo -e "\n${GREEN}正在启动部署任务...${PLAIN}"
    ansible-playbook -i $INI_FILE deploy.yml -f 30

    # 统计结果
    SUCCESS_COUNT=$(ls ./results/*.txt 2>/dev/null | wc -l)
    # 获取当前 ini 文件中的 IP 总数
    TOTAL_IN_INI=$(grep "ansible_port=" $INI_FILE | wc -l)
    
    # 清空并提取失败 IP
    > failed_nodes.txt
    local FAIL_INTERNAL=0
    while read -r line; do
        if [[ $line =~ ^([0-9\.]+)\ .*ansible_port=([0-9]+).*input_order=([0-9]+) ]]; then
            IP="${BASH_REMATCH[1]}"
            PORT="${BASH_REMATCH[2]}"
            ORDER="${BASH_REMATCH[3]}"
            # 提取这一行完整的参数，用于生成 retry_hosts.ini
            FULL_LINE="$line"
            if [ ! -f "./results/$IP.txt" ]; then
                echo "$FULL_LINE" >> failed_nodes.txt
                let FAIL_INTERNAL++
            fi
        fi
    done < $INI_FILE

    echo -e "\n${BLUE}==================================================${PLAIN}"
    echo -e "${BLUE}               🚀 部署执行结果总结               ${PLAIN}"
    echo -e "${BLUE}==================================================${PLAIN}"
    echo -e "${GREEN}本次尝试总数: $TOTAL_IN_INI${PLAIN}"
    echo -e "${GREEN}当前累计成功: $SUCCESS_COUNT${PLAIN}"
    
    if [ $FAIL_INTERNAL -gt 0 ]; then
        echo -e "${RED}本次失败数量: $FAIL_INTERNAL${PLAIN}"
        echo -e "${YELLOW}失败 IP 列表 (序号: IP):${PLAIN}"
        while read -r fline; do
            [[ $fline =~ input_order=([0-9]+) ]] && ORDER_NUM=${BASH_REMATCH[1]}
            [[ $fline =~ ^([0-9\.]+) ]] && IP_VAL=${BASH_REMATCH[1]}
            echo -e "${RED}序号 $ORDER_NUM: $IP_VAL${PLAIN}"
        done < failed_nodes.txt
        
        echo -e "${YELLOW}--------------------------------------------------${PLAIN}"
        read -p "检测到失败节点，是否尝试立即重试部署这些失败节点? (y/n): " DO_RETRY
        if [[ "$DO_RETRY" == "y" || "$DO_RETRY" == "Y" ]]; then
            # 构造临时重试 ini
            cat << 'EOF' > retry_hosts.ini
[nodes]
EOF
            cat failed_nodes.txt >> retry_hosts.ini
            cat << 'EOF' >> retry_hosts.ini
[nodes:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=15'
EOF
            # 递归调用
            run_deployment "retry_hosts.ini"
        fi
    else
        echo -e "${GREEN}恭喜！本次任务内所有服务器均已部署成功！${PLAIN}"
    fi
}

# 启动首次部署
if [ $COUNT -gt 1 ]; then
    run_deployment "hosts.ini"
    
    echo -e "\n${CYAN}节点明文文件: ${WORKDIR}/all_links.txt${PLAIN}"
    echo -e "${CYAN}Base64订阅文件: ${WORKDIR}/subscribe.txt${PLAIN}"
    echo -e "${BLUE}==================================================${PLAIN}"
else
    echo -e "${YELLOW}未添加任何服务器，脚本结束。${PLAIN}"
fi
