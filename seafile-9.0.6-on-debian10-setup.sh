# This Script install Seafile with HTTPS Support!
# see last lines this must be edit manual and set the correct Domain!
# cause Seafile is only clean uploading if the external domain is correct set!!
#  
#  set: 
#   ufw allow 443/tcp
#
# www.linuxonlinehelp.eu 2022

# install MYSQL
sudo apt update
sudo apt install mariadb-server mariadb-client

# set secure Admin MYSQL Passwords!!
sudo mysql_secure_installation

# install python modules REMARK any Errors here BREAK Seafile!
# Seafile INSTALL has NO Python+Python-Module Version CHECK+INFO
# if not working try older seafile Version!!

sudo apt update
sudo apt install python3 python3-{pip,pil,ldap,urllib3,setuptools,mysqldb,memcache,requests}
sudo apt install ffmpeg memcached libmemcached-dev
sudo pip3 install --upgrade pip
sudo pip3 install --timeout=3600 Pillow pylibmc captcha jinja2 sqlalchemy==1.4.3
sudo pip3 install --timeout=3600 django-pylibmc django-simple-captcha python3-ldap mysqlclient

# install Seafile to /srv/ PATH on RASPI use /usbdisk/
export VER="9.0.2"
wget https://download.seadrive.org/seafile-server_${VER}_x86-64.tar.gz
tar -xvf seafile-server_${VER}_x86-64.tar.gz
sudo mv seafile-server-${VER} /srv/seafile
cd /srv/seafile/
sudo ./setup-seafile-mysql.sh

# Set Variables for root ofthen not needed only if seahub.sh echos Errors on Start!
echo "export LC_ALL=en_US.UTF-8" >>~/.bashrc
echo "export LANG=en_US.UTF-8" >>~/.bashrc
echo "export LANGUAGE=en_US.UTF-8" >>~/.bashrc
source ~/.bashrc

# create Autostart for SYSTEMD set correct PATH to seafile.sh+seahub.sh!!

sudo tee /etc/systemd/system/seafile.service<<EOF
[Unit]
Description=Seafile
After= mysql.service
After=network.target

[Service]
Type=forking
ExecStart=/srv/seafile-server-latest/seafile.sh start
ExecStop=/srv/seafile-server-latest/seafile.sh stop

[Install]
WantedBy=multi-user.target
EOF


sudo tee  /etc/systemd/system/seahub.service<<EOF
[Unit]
Description=Seafile
After= mysql.service
After=network.target

[Service]
Type=forking
ExecStart=/srv/seafile-server-latest/seahub.sh start
ExecStop=/srv/seafile-server-latest/seahub.sh stop

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl start seafile && sudo systemctl enable seafile
sudo systemctl start seahub && sudo systemctl enable seahub


# install Apache2
apt-get install apache2
sudo a2enmod rewrite
sudo a2enmod proxy_http
sudo a2enmod ssl
service apache2 restart


#install Webmin for easy SQL-Manage and Certs and Server Monitoring (Load)

wget  https://prdownloads.sourceforge.net/webadmin/webmin_1.998_all.deb
sudo dpkg -i webmin*
apt-get -f install


echo seafile-ok-installed
exit 0
#
#   MANUAL WORK
#
# create VHOST at Apache2 /etc/apache2/sites-available/seafile.conf
# and link it to etc/apache2/sites-enabled/seafile.conf

<VirtualHost *:80>
ServerName seafile
RedirectPermanet / https://seafile
</VirtualHost>

<VirtualHost *:443>
  ServerName seafile
  DocumentRoot /var/www

  SSLEngine On
  SSLCertificateFile /etc/webmin/miniserv.pem    
  SSLCertificateKeyFile /etc/webmin/miniserv.pem 

  Alias /media  /srv/seafile/seafile-server-latest/seahub/media

  <Location /media>
    Require all granted
  </Location>

  RewriteEngine On

  #
  # seafile fileserver
  #
  ProxyPass /seafhttp http://127.0.0.1:8082
  ProxyPassReverse /seafhttp http://127.0.0.1:8082
  RewriteRule ^/seafhttp - [QSA,L]

  #
  # seahub
  #
  SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1
  ProxyPreserveHost On
  ProxyPass / http://127.0.0.1:8000/
  ProxyPassReverse / http://127.0.0.1:8000/
</VirtualHost>

#
#  Major for correct UPLOAD at HTTPS if not you see NETWORK ERROR!
#
#Modifying ccnet.conf
SERVICE_URL = https://seafile.example.com

#Modifying seahub_settings.py
FILE_SERVER_ROOT = 'https://seafile.example.com/seafhttp


#reboot..
