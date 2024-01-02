OE_VERSION="16.0"



INSTALL_NGINX="True"
WEBSITE_NAME="localhost"
OE_USER="odoo"
OE_CONFIG="${OE_USER}-server"
OE_PORT="8069"
LONGPOLLING_PORT="8072"
GENERATE_RANDOM_PASSWORD="True"

CPUS=`grep -c "model name" /proc/cpuinfo`
echo "workers数："$CPUS
val=`expr $CPUS \* 2`

sudo apt update;sudo apt upgrade -y；sudo apt autoremove -y
sudo apt install ssh net-tools vim git postgresql postgresql-client nginx  vim   python3-pip npm -y


sudo  npm install -g less npm install -g less-plugin-clean-css

sudo apt-get install ttf-wqy-zenhei -y

sudo apt-get install ttf-wqy-microhei -y


sudo systemctl start postgresql

cd ~


echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo -u postgres psql -c "CREATE ROLE odooa superuser PASSWORD '123456odoo' login;"

echo -e "\n==== Installing ODOO Server ===="

sudo git clone https://gitee.com/mirrors/odoo.git -b ${OE_VERSION} --depth 1

pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple



echo "

Babel==2.9.1
chardet==4.0.0
cryptography==3.4.8
decorator==4.4.2
docutils==0.16
ebaysdk==2.1.5
freezegun==0.3.15
gevent
greenlet
idna==2.10
Jinja2==2.11.3
libsass==0.20.1
lxml==4.6.5
MarkupSafe==1.1.1
num2words==0.5.9
ofxparse==0.19
passlib==1.7.4
Pillow==9.0.1
polib==1.1.0
psutil==5.8.0
psycopg2-binary;
pydot==1.4.2
pyopenssl==20.0.1
PyPDF2==1.26.0
pyserial==3.5
python-dateutil==2.8.1
python-stdnum==1.16
pytz
pyusb==1.0.2
qrcode==6.1
reportlab
requests==2.25.1
urllib3==1.26.5
vobject==0.9.6.1
Werkzeug==0.16.1
xlrd
XlsxWriter==1.1.2
xlwt==1.3.*
zeep==4.0.0








" > /tmp/requirements.txt

pip install -r /tmp/requirements.txt


if [ $INSTALL_NGINX = "True" ]; then
  echo -e "\n---- Installing and setting up Nginx ----"



sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
sudo touch /etc/nginx/nginx.conf
sudo su root -c "printf '
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 99999;
    # multi_accept on;
}

http {

    ##
    # Basic Settings
    ##

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    # server_tokens off;

    # server_names_hash_bucket_size 64;
    # server_name_in_redirect off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
    ssl_prefer_server_ciphers on;

    ##
    # Logging Settings
    ##

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ##
    # Gzip Settings
    ##

    gzip on;

    # gzip_vary on;
    # gzip_proxied any;
    # gzip_comp_level 6;
    # gzip_buffers 16 8k;
    # gzip_http_version 1.1;
    # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    ##
    # Virtual Host Configs
    ##



server {
  listen 80;

  server_name localhost;

  # Add Headers for odoo proxy mode
  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Client-IP \$remote_addr;
  proxy_set_header HTTP_X_FORWARDED_HOST \$remote_addr;

  #   odoo    log files
  access_log  /var/log/nginx/odoo-access.log;
  error_log       /var/log/nginx/odoo-error.log;

  #   increase    proxy   buffer  size
  proxy_buffers   16  64k;
  proxy_buffer_size   128k;

  proxy_read_timeout 900s;
  proxy_connect_timeout 900s;
  proxy_send_timeout 900s;



  types {
    text/less less;
    text/scss scss;
  }

  #   enable  data    compression
  gzip    on;
  gzip_min_length 1100;
  gzip_buffers    4   32k;
  gzip_types  text/css text/less text/plain text/xml application/xml application/json application/javascript application/pdf image/jpeg image/png;
  gzip_vary   on;
  client_header_buffer_size 4k;
  large_client_header_buffers 4 64k;
  client_max_body_size 0;

  location / {
    proxy_pass    http://127.0.0.1:8069;
  }

  location /longpolling {
    proxy_pass http://127.0.0.1:8072;
  }

  location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
    expires 2d;
    proxy_pass http://127.0.0.1:8069;
  }

  location ~ /[a-zA-Z0-9_-]*/static/ {
    proxy_cache_valid 200 302 60m;
    proxy_cache_valid 404      1m;
    proxy_buffering    on;
    expires 864000;
    proxy_pass    http://127.0.0.1:8069;
  }
}

}







' >> /etc/nginx/nginx.conf"

  sudo service nginx reload
else
  echo "Nginx isn't installed due to choice of the user!"
fi






echo -e "* Create server config file"


sudo touch /etc/${OE_CONFIG}.conf
echo -e "* Creating server config file"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "* Generating random admin password"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
#sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"

sudo su root -c "printf 'db_port = 5432\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'db_host = localhost\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'db_user = odooa\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'workers  = ${val}\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'db_password = 123456odoo \n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'addons_path=~/odoo/addons,\n' >> /etc/${OE_CONFIG}.conf"



echo -e "* Create odoo server service file"


sudo touch /etc/odoo${OE_CONFIG}.service

sudo su root -c "printf '[Unit]
Description=Odoo Open Source ERP and CRM
After=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
ExecStart=/usr/bin/python3 /home/${USER}/odoo/odoo-bin --config /etc/${OE_CONFIG}.conf
KillMode=mixed

[Install]
WantedBy=multi-user.target
' >> /etc/odoo${OE_VERSION}.service"


echo -e "* setting service autostart "


sudo cp /etc/odoo${OE_VERSION}.service /etc/systemd/system/

sudo systemctl daemon-reload

sudo systemctl enable nginx

sudo systemctl enable postgresql


sudo systemctl enable odoo${OE_VERSION}.service



echo -e "*   Start odoo service"


sudo systemctl start nginx

sudo systemctl start postgresql

sudo systemctl start odoo${OE_VERSION}.service

sudo systemctl enable odoo${OE_VERSION}.service



sudo reboot 
