sudo apt update
sudo apt install mariadb-server mariadb-client

sudo mysql_secure_installation

sudo apt update
sudo apt install python3 python3-{pip,pil,ldap,urllib3,setuptools,mysqldb,memcache,requests}
sudo apt install ffmpeg memcached libmemcached-dev
sudo pip3 install --upgrade pip
sudo pip3 install --timeout=3600 Pillow pylibmc captcha jinja2 sqlalchemy==1.4.3
sudo pip3 install --timeout=3600 django-pylibmc django-simple-captcha python3-ldap mysqlclient

export VER="9.0.2"
wget https://download.seadrive.org/seafile-server_${VER}_x86-64.tar.gz

tar -xvf seafile-server_${VER}_x86-64.tar.gz
sudo mv seafile-server-${VER} /srv/seafile



cd /srv/seafile/
sudo ./setup-seafile-mysql.sh

echo "export LC_ALL=en_US.UTF-8" >>~/.bashrc
echo "export LANG=en_US.UTF-8" >>~/.bashrc
echo "export LANGUAGE=en_US.UTF-8" >>~/.bashrc
source ~/.bashrc




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



apt-get install apache2

sudo a2enmod rewrite
sudo a2enmod proxy_http
sudo a2enmod ssl

service apache2 restart


#install webmin

wget  https://prdownloads.sourceforge.net/webadmin/webmin_1.998_all.deb
sudo dpkg -i webmin*
apt-get -f install



exit 0

###

<VirtualHost *:443>
  ServerName seafile
  DocumentRoot /var/www

  SSLEngine On
  SSLCertificateFile /etc/webmin/miniserv.pem    # Path to your fullchain.pem
  SSLCertificateKeyFile /etc/webmin/miniserv.pem  # Path to your privkey.pem

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





Modifying ccnet.conf

SERVICE_URL = https://seafile.example.com

Modifying seahub_settings.py


FILE_SERVER_ROOT = 'https://seafile.example.com/seafhttp


reboot..














































