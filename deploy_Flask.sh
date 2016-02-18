#!/bin/bash

echo
echo "##########################################################"
echo "#                                                        #"
echo "#      deploy flask with Uwsgi and nginx on centos6      #"
echo "#                                                        #"
echo "##########################################################"
echo

echo
echo "##################################################################"
echo "#                                                                #"
echo "#      Downloading, Compiling and install python on centos6      #"
echo "#                                                                #"
echo "##################################################################"
echo

#yum -y update
#yum groupinstall -y 'development tools'
#yum install -y zlib-devel bzip2-devel openssl-devel xz-libs wget
#cd /tmp
#rm -rf Python-2.7.6.tar.xz >/dev/null 2>&1
#wget http://www.python.org/ftp/python/2.7.8/Python-2.7.8.tar.xz
#tar -xvf Python-2.7.8.tar.xz
#cd Python-2.7.8
## Start the configuration (setting the installation directory)
## By default files are installed in /usr/local.
## You can modify the --prefix to modify it (e.g. for $HOME).
#./configure --prefix=/usr/local
#make && make altinstall
## use python2.7 withou use the default python version
#export PATH="/usr/local/bin:$PATH"
## curl -O https://raw.github.com/pypa/pip/master/contrib/get-pip.py
## python get-pip.py


echo
echo "#####################################################"
echo "#                                                   #"
echo "#      update system and install some software      #"
echo "#                                                   #"
echo "#####################################################"
echo

yum install nginx  python-pip -y
pip install --upgrade pip
pip install virtualenv
chkconfig nginx on

echo
echo "#####################################################"
echo "#                                                   #"
echo "#             install flask environment             #"
echo "#                                                   #"
echo "#####################################################"
echo

mkdir -p /var/www/flask_api
cd /var/www/flask_api
rm -rf *
virtualenv venv
source venv/bin/activate
pip install flask
pip install uwsgi

echo
echo "#####################################################"
echo "#                                                   #"
echo "#              edit some config files               #"
echo "#                                                   #"
echo "#####################################################"
echo

cat > /etc/nginx/conf.d/default.site.conf << EOF
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
EOF

cat > /var/www/flask_api/uwsgi_config.ini << EOF
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
EOF

cat > /var/www/flask_api/manager.py << EOF
#!/usr/bin/env python

from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
        return "<span style='color:red'>Flask is running...</span>\n"
EOF

uwsgi /var/www/flask_api/uwsgi_config.ini &
service nginx restart

# if selinux if on,set selinux rules
if  sestatus -v | grep enabled
then
yum install policycoreutils-python
grep nginx /var/log/audit/audit.log | audit2allow -m nginx
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
semodule -i nginx.pp
fi
