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

