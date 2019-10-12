#!/bin/bash

# Autogenerate MYSQL password if it was not specified
echo -e "\n=> Setting up MYSQL password"
if [[ -z $MYSQL_PASSWORD ]] && [[ ! -f /home/pi/mysql_passwd ]]; then
   MYSQL_PASSWORD=$(dd if=/dev/urandom bs=10 count=1 2>/dev/null | base64)
   echo $MYSQL_PASSWORD > /home/pi/mysql_passwd
fi

# Create pi user
id pi > /dev/null 2>&1
if [[ $? != 0 ]]; then 
  echo -e "\n=> Adding pi user"
  useradd pi -m -p $MYSQL_PASSWORD > /dev/null 2>&1 
  echo -e "\n# pi user\npi ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers; 
else
 echo -e "\n=> User pi already exists"
fi

#Install / update emoncms
echo -e "\n=> Installing emoncms"
rm -rf /var/www/html
rm -rf /home/pi/emailreport
rm -rf /home/pi/sync
rm -rf /home/pi/emonpi
rm -rf /usr/local/bin/emoncms_usefulscripts
git clone https://github.com/emoncms/emoncms.git /var/www/html
git clone https://github.com/emoncms/app.git /var/www/html/Modules/app
git clone https://github.com/emoncms/usefulscripts.git /usr/local/bin/emoncms_usefulscripts
git clone https://github.com/emoncms/dashboard.git /var/www/html/Modules/dashboard
git clone https://github.com/emoncms/device.git /var/www/html/Modules/device
git clone https://github.com/emoncms/graph.git /var/www/html/Modules/graph
git clone https://github.com/emoncms/sync.git /home/pi/sync
git clone https://github.com/openenergymonitor/emonpi.git /home/pi/emonpi
git clone https://github.com/emoncms/postprocess.git /home/pi/postprocess
ln -s /home/pi/sync/sync-module /var/www/html/Modules/sync
ln -s /home/pi/postprocess/postprocess-module /var/www/html/Modules/postprocess
ln -s /var/www/html /var/www/emoncms
cp /home/pi/postprocess/default.postprocess.settings.php /home/pi/postprocess/postprocess.settings.php

# Prepare mysql
if [[ ! -f /etc/mysql/my.cnf ]]; then
  mv /root/my.cnf /etc/mysql/
fi

# Initialize MySQL if it not initialized yet
MYSQL_HOME="/var/lib/mysql"
if [[ ! -d $MYSQL_HOME/mysql ]]; then
  echo -e "\n=> Installing MySQL ..."
  mysql_install_db > /dev/null 2>&1
  chown -R mysql:mysql /var/lib/mysql/ > /dev/null 2>&1
  if [[ ! -d /var/run/mysqld ]]; then
    mkdir -p /var/run/mysqld > /dev/null 2>&1
    chown mysql:mysql /var/run/mysqld > /dev/null 2>&1
  fi
else
  echo -e "\n=> Using an existing volume of MySQL (or mysql_install_db already completed)"
fi

# Ensuring ownership is set correctly on directories
chown -R mysql:mysql /var/lib/mysql/ > /dev/null 2>&1
chown -R mysql:mysql /var/run/mysqld > /dev/null 2>&1
chown -R www-data:www-data /var/www/html/ > /dev/null 2>&1
chown -R www-data:www-data /var/lib/phpfina/ > /dev/null 2>&1
chown -R www-data:www-data /var/lib/phpfiwa/ > /dev/null 2>&1
chown -R www-data:www-data /var/lib/phptimeseries/ > /dev/null 2>&1

# Run db scripts only if there's no existing emoncms database
EMON_HOME="/var/lib/mysql/emoncms"
if [[ ! -d $EMON_HOME ]]; then
  echo -e "\n=> Running db.sh to configure database"
  /db.sh
fi

# Update the settings file for emoncms
EMON_DIR="/var/www/html"
SETPHP="$EMON_DIR/settings.ini"
if [[ ! -f $SETPHP ]]; then
  echo -e "\n=> Creating settings.ini\n"
  touch "$EMON_DIR/settings.ini"
  # Configure MySQL
  cat <<EOF > "$EMON_DIR/settings.ini"
; -----------------------------------------------------
; emoncms settings.ini file
; -----------------------------------------------------

; Mysql database settings
[sql]
server   = "127.0.0.1"
database = "emoncms"
username = "emoncms"
password = "$MYSQL_PASSWORD"
port     = 3306
; Skip database setup test - set to false once database has been setup.
dbtest   = false

; Redis
[redis]
enabled = false
host = '127.0.0.1'
port = 6379
auth = ''
dbnum = ''
prefix = 'emoncms'

; Default feed viewer: "vis/auto?feedid=" or "graph/" - requires module https://github.com/emoncms/graph
feedviewpath = "vis/auto?feedid="

; If installed on Emonpi, allow admin menu tools
enable_admin_ui = true
EOF

  if [[ -n $MQTT_HOST ]]; then
    if [[ -z $MQTT_PORT ]]; then
      MQTT_PORT="1883"
    fi
    cat <<EOF >> "$EMON_DIR/settings.ini"
; MQTT
[mqtt]
enabled = true
host = '$MQTT_HOST'
port = $MQTT_PORT
user = '$MQTT_USER'
password = '$MQTT_PASS'
basetopic = 'emoncms'
client_id = 'emoncms'
EOF
  fi    

  if [[ -n $EMAIL_FROM ]] && [[ -n $EMAIL_HOST ]]; then
    cat <<EOF >> "$EMON_DIR/settings.ini"
; Email SMTP, used for password reset or other email functions
[smtp]
default_emailto = '$EMAIL_TO'
host = "$EMAIL_HOST"
port = "$EMAIL_PORT"
from_email = '$EMAIL_FROM'
from_name = '$EMAIL_NAME'
encryption = "$EMAIL_ENCRYPT"
username = "$EMAIL_USER"
password = "$EMAIL_PASS"
EOF
  fi
  
  if [[ -z $EMAIL_ENCRYPT ]]; then
    sed -i 's/encryption\ =\ \"\"/\;encryption\ =\ \"\"/g' "$EMON_DIR/settings.ini"
  fi

  if [[ -z $EMAIL_USERNAME ]]; then
    sed -i "/\[smtp\]/{n;n;n;n;n;n;n;s/.*/\;username\ =\ \"\"/}" "$EMON_DIR/settings.ini"    # Disable SMTP username
  fi

  if [[ -z $EMAIL_PASSWORD ]]; then
    sed -i "/\[smtp\]/{n;n;n;n;n;n;n;n;s/.*/\;password\ =\ \"\"/}" "$EMON_DIR/settings.ini"    # Disable SMTP password
  fi

  if [[ ! -f /home/pi/backup.php ]]; then
    cp /usr/local/bin/emoncms_usefulscripts/backup/backup.php /home/pi/backup.php
    cp -R /usr/local/bin/emoncms_usefulscripts/backup/lib /home/pi/
  fi
fi

# Disable directory listing on Apache
sed -i 's/#    Options -Indexes/    Options -Indexes/g' /var/www/html/.htaccess

echo "==========================================================="
echo "The username and password for the emoncms user is:"
echo ""
echo "   username: emoncms"
echo "   password: $MYSQL_PASSWORD"
echo ""
echo "==========================================================="

# Setup Apache
source /etc/apache2/envvars

# Configure cron
if [[ ! -f /var/spool/cron/crontabs/pi ]]; then
  mv /root/crontab /var/spool/cron/crontabs/pi
fi
touch /etc/crontab /etc/cron.d/* /var/spool/cron/crontabs/*
chmod 0600 /etc/cron.d/* /var/spool/cron/crontabs/pi

# Configure logs
touch /var/log/emoncms/emoncms.log
touch /var/log/emoncms/postprocess.log
chmod 666 /var/log/emoncms/emoncms.log
chmod 666 /var/log/emoncms/postprocess.log

# Use supervisord to start all processes
supervisord -c /etc/supervisor/conf.d/supervisord.conf
