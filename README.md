<s>
# -vle-real-tls-静态伪装

### 第一步：管理机环境创建需要运行的脚本
```bash
apt update && apt install -y ansible sshpass uuid-runtime
```

```bash
mkdir -p /etc/ansible && echo -e "[defaults]\nhost_key_checking = False" > /etc/ansible/ansible.cfg
```

### 第二步：创建文件 将上面的 hosts.ini 和 deploy.yml 内容保存到管理机的当前目录下。


### 第三步：一键运行
```bash
mkdir -p temp_links
ansible-playbook -i hosts.ini deploy.yml -f 50
```

### 注意：该脚本会在服务机上的443端口生成一个 vle-real-tls-静态伪装 的 jd
### 确保服务器放行对应端口

1、支持变动端口：ansible_port 字段会自动处理所有 SSH 连接。

2、错误隔离：如果 500 台里有几台因为网络问题失败了，ignore_errors 和生成的 ERROR 标记能让你一眼看出哪些机器没跑成功，而不会中断整个部署。

3、无乱序丢失：temp_links/ 的设计方案彻底解决了你之前提到的链接丢失和乱序问题。




### 方案总结与优势
极简操作：你只需要维护一个   ```hosts.ini```   列表，然后运行一条   ```ansible-playbook```   命令。

抗冲突设计：每个节点生成的链接先存在 temp_links/ 下的独立文件里，最后由管理机统一合并到   ```final_nodes.txt```  ，彻底告别数据丢失。

全自动化：从   ```d11.sh```   初始化、Nginx 伪装、Reality 私钥生成到最终导出链接，全部一气呵成。



批量卸载 下载cleanup.yml 到/root
然后
```bash
ansible-playbook -i hosts.ini cleanup.yml -f 50
```


### 只需要：
1. 准备好 hosts.ini -> 2. 运行一次 deploy.yml。所有的事情（包括生成链接）都会在这一步里全部完成。

如果有任何特定的机器部署失败（比如 PLAY RECAP 里显示 failed=1），你可以运行： ansible-playbook deploy.yml --limit 失败的IP 进行重试。

# 1. 更新系统并安装 Ansible 与依赖
```bash
apt update && apt install ansible sshpass python3 curl -y
```

# 2. 创建并进入工作目录
```bash
mkdir -p ~/reality_batch && cd ~/reality_batch && mkdir -p results
```

# 3. 上传 ```deploy.yml``` 和 ```hosts.ini```

# 4. 执行部署，-f 30 表示并发 30 台同时跑

```bash
ansible-playbook deploy.yml -f 30
```

# 5. 一键卸载
```bash
cat <<'EOF' > uninstall.yml
---
- name: 彻底卸载 Xray 和伪装网页
  hosts: nodes
  gather_facts: no
  tasks:
    - shell: |
        systemctl stop xray nginx || true
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove || true
        apt-get purge -y nginx || true
        rm -rf /usr/local/etc/xray /var/www/html/index.html /tmp/node_info.txt
        apt-get autoremove -y
EOF
```


# 6. 执行卸载
```bash
ansible-playbook uninstall.yml -f 30
```

# 7. 验证连接是否成功
```bash
ansible nodes -m ping
```
# <mark>新一键脚本</mark>

```bash
wget -N https://raw.githubusercontent.com/weilaikeqi886/-vle-real-tls-/main/install3.sh && bash install3.sh
```
# <mark>这是一个带交互输入ssh信息的一键脚本</mark>

```bash
wget -N https://raw.githubusercontent.com/weilaikeqi886/-vle-real-tls-/main/install_interactive.sh && bash install_interactive.sh
```

# <mark>然后执行这个</mark>

```bash
cd /root/reality_batch && ansible-playbook -i hosts.ini deploy.yml -f 30
```

</s>


# <mark>注意、注意、注意</mark>
# <mark>注意、注意、注意</mark>
# <mark>注意、注意、注意</mark>
  随便选择一个debian系统的vps作为主控机，对被控机进行批量控制，在被控机上生成vless + reality + tls + 网页伪装 的节点。
  生成的节点全部回收并保存在主控机的 /root/reality_batch/all_links.txt

# <mark>注意、最新一键版本仅需要主控机执行下方一键脚本</mark>
# <mark>注意、最新一键版本仅需要主控机执行下方一键脚本</mark>
# <mark>注意、最新一键版本仅需要主控机执行下方一键脚本</mark>
# <mark>真一键+debian系统更新源设置并更新系统+交互+自动执行+被控机随机粒子云网页伪装效果</mark>

```bash
wget -N https://raw.githubusercontent.com/weilaikeqi886/-vle-real-tls-/main/install_interactive6.sh && bash install_interactive6.sh
```



