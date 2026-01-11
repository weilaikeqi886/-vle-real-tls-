# -vle-real-tls-静态伪装
第一步：管理机创建环境需要运行的脚本
```apt update && apt install -y ansible sshpass uuid-runtime
```mkdir -p /etc/ansible && echo -e "[defaults]\nhost_key_checking = False" > /etc/ansible/ansible.cfg

第二步：创建文件 将上面的 hosts.ini 和 deploy.yml 内容保存到管理机的当前目录下。

第三步：一键运行
``` mkdir -p temp_links
ansible-playbook -i hosts.ini deploy.yml -f 50 ```
