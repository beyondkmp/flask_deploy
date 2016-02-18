# deploy_flask_centos6
在centos上部署flask应用的自动化脚本

具体的使用步骤：

1. 用root权限运行脚本

```
chmod +x deploy_Flask.sh
./deploy_Flask.sh
```

2. 测试是否安装成功,运行下面的命令，如果正常输出Flask is runnig则说明部署成功

```
curl http://127.0.0.1
```

## 参考

1. [发一个 Fedora23 上自动搭建、配置 Flask 的 shell 脚本](https://www.v2ex.com/t/254879)
