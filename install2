#!/bin/bash

# 定义颜色
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PLAIN='\033[0m'

clear
echo -e "${BLUE}==================================================${PLAIN}"
echo -e "${BLUE}       REALITY 1000台服务器批量部署环境初始化       ${PLAIN}"
echo -e "${BLUE}==================================================${PLAIN}"

# 1. 询问部署端口
read -p "$(echo -e ${YELLOW}"请输入想要在哪个端口上部署？(直接回车默认443): "${PLAIN})" PORT
[[ -z "$PORT" ]] && PORT="443"
echo -e "${GREEN}端口已设定为: $PORT${PLAIN}"

# 2. 安装基础依赖
echo -e "${YELLOW}正在安装必要组件...${PLAIN}"
apt update && apt install ansible sshpass python3 curl -y > /dev/null 2>&1

# 3. 创建目录结构
WORKDIR="/root/reality_batch"
mkdir -p ${WORKDIR}/results
cd ${WORKDIR}

# 4. 生成 hosts.ini (简单结构，直接写入)
echo "[nodes]" > hosts.ini
echo "# 格式：IP ansible_port=22 ansible_ssh_pass=\"密码\"" >> hosts.ini
echo "" >> hosts.ini
echo "[nodes:vars]" >> hosts.ini
echo "ansible_ssh_user=root" >> hosts.ini
echo "ansible_python_interpreter=/usr/bin/python3" >> hosts.ini
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=15'" >> hosts.ini

# 5. 生成 deploy.yml (采用 Base64 编码写入，防止任何格式被 Shell 破坏)
# 这一段密文解码后就是完美的 deploy.yml，包括所有缩进和 Python 脚本
cat << 'EOF' | base64 -d > deploy.yml
LS0tCi0gbmFtZTogMTAwMHRh5pyN5Yqh5ZmoIFJFQUxJVFlf5YWo6Ieq5Yqo6YOo572yCiAgaG9z
dHM6IG5vZGVzCiAgZ2F0aGVyX2ZhY3RzOiBubwogIHZhcnM6CiAgICBsaXN0ZW5fcG9ydDogTVlf
Q1VTVE9NX1BPUlQKICAgIGRlc3RfZG9tYWluOiAiZGwuZ29vZ2xlLmNvbSIKCiAgdGFza3M6CiAg
ICAtIG5hbWU6IDEuIFvmnKzlstandardG97IOWInOWni+WMliBYcmF5IOaooeadvQogICAgICBkZWxl
Z2F0ZV90bzogbG9jYWxob3N0CiAgICAgIHJ1bl9vbmNlOiB0cnVlCiAgICAgIGNvcHk6CiAgICAg
ICAgZGVzdDogIi4veHJheS5jb25mLmoyIgogICAgICAgIGNvbnRlbnQ6IHwKICAgICAgICAgIHsK
ICAgICAgICAgICAgICAibG9nIjogeyAibG9nbGV2ZWwiOiAid2FybmluZyIgfSwKICAgICAgICAg
ICAgICAiaW5ib3VuZHMiOiBbeyKwb3J0Ijoge3sgbGlzdGVuX3BvcnQgfX0sICJwcm90b2NvbCI6
ICJ2bGVzcyIsICJzZXR0aW5ncyI6IHsgImNsaWVudHMiOiBbeyJpZCI6ICJ7eyBteV91dWlkIH19
IiwgImZsb3ciOiAieHRscy1ycHJ4LXZpc2lvbiJ9XSwgImRlY3J5cHRpb24iOiAibm9uZSIsICJz
dHJlYW1TZXR0aW5ncyI6IHsgIm5ldHdvcmsiOiAidGNwIiwgInNlY3VyaXR5IjogInJlYWxpdHki
LCAicmVhbGl0eVNldHRpbmdzIjogeyAic2hvdyI6IGZhbHNlLCAiZGVzdCI6ICJ7eyBkZXN0X2Rv
bWFpbiB9fTo0NDMiLCAieHZlciI6IDAsICJzZXJ2ZXJOYW1lcyI6IFsie3sgZGVzdF9kb21haW4g
fX0iXSwgInByaXZhdGVLZXkiOiAie3sgcHJpdl9rZXkgfX0iLCAic2hvcnRJZHMiOiBbIjZhMmIz
YzRkIl0gfSB9IH1dLCAib3V0Ym91bmRzIjogW3sgInByb3RvY29sIjogImZyZWVkb20iIH1dfQoK
ICAgIC0gbmFtZTogMi4gW2Im5o6n5py6XSAn546v5aKD5L+u5aSN5LiO57ay5a2Q5LqR572R6aG1
6YOo572yJwogICAgICBzaGVsbDogfAogICAgICAgIGFwdC1nZXQgdXBkYXRlICYmIGFwdC1nZXQg
aW5zdGFsbCAteSBjdXJsIG50cGRhdGUgbmdpbngKICAgICAgICBudHBkYXRlIC11IHBvb2wubnRw
Lm9yZyB8fCB0cnVlCiAgICAgICAgaXB0YWJsZXMgLUYgJiYgaXB0YWJsZXMgLVgKICAgICAgICBp
cHRhYmxlcyAtUCBJTlBVVCBBQ0NFUFQgJiYgaXB0YWJsZXMgLVAgRk9SV0FSRCBBQ0NF
