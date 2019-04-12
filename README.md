# 使用nginx和uwsgi部署flask应用

## 安装python3

1. 安装编译python的信赖包

    ```
    yum install -y gcc make libffi-devel zlib-devel bzip2-devel openssl-devel xz-libs wget
    ```

2. 编译安装python的最新版本

    * 从官网下载最新的源代码并解压缩

        ```
        wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tar.xz
        tar -xvf Python-3.7.3.tar.xz
        ```

    * 编译安装

        ```
        cd Python-3.7.3
        #安装到/usr/local下与自带的python区分开
        ./configure --prefix=/usr/local
        make && make install
        ```
    * 设置PATH，更改默认python

        ```
        export PATH="/usr/local/bin:$PATH"
        ```

## 安装使用uwsgi

为了统一管理，在python的虚拟环境下安装使用uwsgi,不使用全局的uwsgi

```bash
mkdir -p /var/www/flask_api
cd /var/www/flask_api
python -m venv venv
source venv/bin/activate
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

## 编译安装nginx

1. 安装信赖包

    ```
    yum install pcre-devel gcc make zlib-devel lua-devel perl
    ```

2. 下载最新版本的openssl和nginx源代码

    ```
    wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
    wget https://nginx.org/download/nginx-1.14.2.tar.gz
    ```

3. 编译安装

    ```
    tar -xvf openssl-1.1.1b.tar.gz
    tar -xvf nginx-1.14.2.tar.gz
    cd nginx-1.14.2
    ./configure  --prefix=/usr/local/nginx --with-stream --with-stream_ssl_preread_module  --with-http_v2_module --with-http_ssl_module  --with-pcre  --with-openssl=../openssl-1.1.1b --with-openssl-opt='enable-tls1_3'
    make -j 4
    make install
    ```

4. 添加systemctl配置, 添加` /usr/lib/systemd/system/nginx.service`,并将下面内容写入

    ```
    [Unit]
    Description=The NGINX HTTP and reverse proxy server
    After=syslog.target network.target remote-fs.target nss-lookup.target

    [Service]
    Type=forking
    PIDFile=/usr/local/nginx/logs/nginx.pid
    ExecStartPre=/usr/local/nginx/sbin/nginx -t
    ExecStart=/usr/local/nginx/sbin/nginx
    ExecReload=/bin/kill -s HUP $MAINPID
    ExecStop=/bin/kill -s QUIT $MAINPID
    PrivateTmp=true

    [Install]
    WantedBy=multi-user.target
    ```

5. 修改nginx配置, 先使用`useradd nginx`添加nginx用户, 再将下面内容覆盖/usr/local/nginx/conf/nginx.conf, 最后在/usr/local/nginx/conf下面添加vhosts文件夹，最后所有域名的配置都可以放到这个目录下面。

	```nginx
	user  nginx;
	worker_processes  8;

	events {
		worker_connections  1024;
	}


	http {
		include       mime.types;
		default_type  application/octet-stream;

		log_format  main  '$remote_addr - $request_time [$time_local] "$request" '
						  '$status $body_bytes_sent $bytes_sent $content_length $request_length "$http_referer" '
						  '"$http_user_agent" "$http_x_forwarded_for"';

		access_log  logs/access.log  main;

		sendfile        on;
		#tcp_nopush     on;

		#keepalive_timeout  0;
		keepalive_timeout  65;

		#gzip  on;
		include vhosts/*.conf;
	}
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
