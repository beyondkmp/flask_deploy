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


## 参考

1. [发一个 Fedora23 上自动搭建、配置 Flask 的 shell 脚本](https://www.v2ex.com/t/254879)
2. [Installing Python 2.7.8 on CentOS 6.5](http://bicofino.io/2014/01/16/installing-python-2-dot-7-6-on-centos-6-dot-5/)
