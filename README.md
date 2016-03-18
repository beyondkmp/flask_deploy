# deploy_flask_centos6
在centos上部署flask应用的自动化脚本

## 具体的使用步骤：

1. 用root权限运行脚本

    ```
    chmod +x deploy_Flask.sh
    ./deploy_Flask.sh
    ```

2. 测试是否安装成功,运行下面的命令，如果正常输出Flask is runnig则说明部署成功

    ```
    curl http://127.0.0.1
    ```

## 手动安装的全过程

### 在centos6下安装python2.7

1. 安装相应的开发包
    ```
    yum groupinstall -y 'development tools'
    ```
2. 安装SSL,bz2和zlib用来编译安装python及其其它一些组件

    ```
    yum install -y zlib-devel bzip2-devel openssl-devel xz-libs wget
    ```

3. 编译安装python的最新版本

    * 从官网下载最新的源代码并解压缩

        ```
        wget http://www.python.org/ftp/python/2.7.8/Python-2.7.8.tar.xz
        tar -xvf Python-2.7.8.tar.xz
        ```

    * 编译安装

        ```
        cd Python-2.7.8
        #安装到/usr/local下与自带的python区分开
        ./configure --prefix=/usr/local
        make && make install
        ```
    * 设置PATH，更改默认python

        ```
        export PATH="/usr/local/bin:$PATH"
        ```

### 安装pip与virtualenv

1. install setuptools

    ```
    wget --no-check-certificate https://pypi.python.org/packages/source/s/setuptools/setuptools-1.4.2.tar.gz

    # Extract the files:
    tar -xvf setuptools-1.4.2.tar.gz
    cd setuptools-1.4.2

    # Install setuptools using the Python 2.7.8:
    python2.7 setup.py install
    ```
2. install pip

    ```
    curl https://raw.githubusercontent.com/pypa/pip/master/contrib/get-pip.py | python2.7 -
    ```

3. install virtualenv

    ```
    pip2.7 install virtualenv
    ```

### 安装使用uwsgi

为了统一管理，在python的虚拟环境下安装使用uwsgi,不使用全局的uwsgi

```
mkdir -p /var/www/flask_api
cd /var/www/flask_api
virtualenv env
source env/bin/activate
pip install flask uwsgi
```

接下来可以用uWSGI来跑Flask应用

```
uwsgi --http 0.0.0.0:8080 --home env --wsgi-file flask_uwsgi.py --callable app --master
```

测试上面的程序是否成功

```
curl http://127.0.0.1:8080
```

### 安装最新版本的nginx

#### 方法一

#### 安装EPEL

EPEL是Extra Packages for Enterprise Linux的简称。因为在默认的repository里面没有包含最新版本的nginx,安装EPEL后可以确保Centos上的nginx保持的最新版本。

安装EPEL的命令如下：

```
sudo yum install epel-release
```
#### 方法二

设置repo,新建/etc/yum.repos.d/nginx.repo,在此文件中添加如下内容:

```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
```

#### 安装nginx

```
sudo yum install nginx
```

### 配置nginx与uWSGI

配置nginx,主要是用来反向代理指向uWSGI

在/etc/nginx/conf.d/default.site.conf(不存在就touch此文件)添加下面内容

```
server
{
        listen                  80;
        server_name             127.0.0.1;
        root                    /var/www/flask_api;

        location /
        {
                include         uwsgi_params;
                uwsgi_pass      unix:/tmp/uwsgi.sock;
        }
}
```

在/var/www/flask_api下面添加uwsgi_config.ini，添加下面的代码：

```
[uwsgi]

socket = /tmp/uwsgi.sock
chmod-socket = 644
uid = nginx
gid = nginx

chdir = /var/www/flask_api
home = /var/www/flask_api/venv
wsgi-file = /var/www/flask_api/manager.py
callable = app
plugins = python

master = true
vacuum = true
```

最后启动uwsgi和重启nginx服务,在python虚拟环境下运行

```
uwsgi /var/www/flask_api/uwsgi_config.ini &
service nginx restart
```

### 遇到的问题
1. 关于打开SELINUX时权限问题

    具体的问题从/var/log/nginx/error.log里面可以查到以下错误
    ```
    2016/02/17 13:32:39 [crit] 18951#0: *1 connect() to unix:/tmp/uwsgi.sock fai    led (13: Permission denied) while connecting to upstream, client: 127.0.0.1,     server: 127.0.0.1, request: "GET /helloworld HTTP/1.1", upstream: "uwsgi://    unix:/tmp/uwsgi.sock:", host: "127.0.0.1"
    ```

    解决方法，具体参考[Nginx can't connect to uWSGI socket with correct permissions](http://superuser.com/questions/809527/nginx-cant-connect-to-uwsgi-socket-with-correct-permissionsnx can't connect to uWSGI socket with correct permissions)

    先安装audit2allow,`yum install policycoreutils-python`

    再添加以下规则：

    ```
    grep nginx /var/log/audit/audit.log | audit2allow -m nginx
    grep nginx /var/log/audit/audit.log | audit2allow -M nginx
    semodule -i nginx.pp
    ```

## 参考

1. [发一个 Fedora23 上自动搭建、配置 Flask 的 shell 脚本](https://www.v2ex.com/t/254879)
2. [Installing Python 2.7.8 on CentOS 6.5](http://bicofino.io/2014/01/16/installing-python-2-dot-7-6-on-centos-6-dot-5/)
3. [mking/flask-uwsgi](https://github.com/mking/flask-uwsgi)
4. [How To Deploy Flask Web Applications Using uWSGI Behind Nginx on CentOS 6.4](https://www.digitalocean.com/community/tutorials/how-to-deploy-flask-web-applications-using-uwsgi-behind-nginx-on-centos-6-4)
5. [使用uwsgi和Nginx部署flask应用](https://segmentfault.com/a/1190000002411626)
6. [阿里云部署 Flask + WSGI + Nginx 详解](http://www.cnblogs.com/Ray-liang/p/4173923.html)
7. [audit2why](https://screamingadmin.wordpress.com/2012/08/20/audit2why/)
8. [SELinux policy for nginx and GitLab unix socket in Fedora 19](http://axilleas.me/en/blog/2013/selinux-policy-for-nginx-and-gitlab-unix-socket-in-fedora-19/)
9. [nginx install官网](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/#)
