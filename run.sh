#!/bin/bash

# Create pi user
id pi > /dev/null 2>&1
if [[ $? != 0 ]]; then 
  echo -e "\n=> Adding pi user"
  useradd pi -m -p $MYSQL_PASSWORD > /dev/null 2>&1 
  echo -e "\n# pi user\npi ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers; 
else
 echo -e "\n=> User pi already exists"
fi

#Install emoncms
INDEX="/var/www/html/settings.php"
if [[ ! -d $INDEX ]]; then
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
  ln -s /home/pi/sync/sync-module /var/www/html/Modules/sync
  ln -s /var/www/html /var/www/emoncms
else
  echo -e "\n=> Using existing emoncms installation"
fi

# Check that user has supplied a MYSQL_PASSWORD
if [[ -z $MYSQL_PASSWORD ]]; then
  echo 'Ensure that you have supplied a password using the -e MYSQL_PASSWORD="mypass"'
  exit 1;
fi

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
  if [[ ! -f /var/run/mysqld ]]; then
    mkdir -p /var/run/mysqld > /dev/null 2>&1
    chown mysql:mysql /var/run/mysqld > /dev/null 2>&1
  fi
else
  echo -e "\n=> Using an existing volume of MySQL"
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
SETPHP="$EMON_DIR/settings.php"
if [[ ! -f $SETPHP ]]; then
  echo -e "\n=> Updating settings.php\n"
  cp "$EMON_DIR/default.settings.php" "$EMON_DIR/settings.php"
  sed -i "s/_DB_USER_/emoncms/" "$EMON_DIR/settings.php"
  sed -i "s/_DB_PASSWORD_/$MYSQL_PASSWORD/" "$EMON_DIR/settings.php"
  sed -i "s/localhost/127.0.0.1/" "$EMON_DIR/settings.php"
  sed -i "s/redis_enabled = false;/redis_enabled = true;/" "$EMON_DIR/settings.php"
  sed -i 's/$homedir = "\/home\/username"/$homedir = "\/home\/pi"/' "$EMON_DIR/settings.php"
  # Configure MQTT if host is specified
  if [[ -n $MQTT_HOST ]]; then
    sed -i "s/mqtt_enabled = false;/mqtt_enabled = true;/" "$EMON_DIR/settings.php"
    sed -i "s/mqtt_server = array( 'host'     => '127.0.0.1'/mqtt_server = array( 'host'     => '$MQTT_HOST'/g" "$EMON_DIR/settings.php"
  fi
  if [[ ! -n /home/pi/backup.php ]]; then
    cp /usr/local/bin/emoncms_usefulscripts/backup/backup.php /home/pi/backup.php
  fi
fi

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
chmod 0600 /etc/cron.d/emoncms /var/spool/cron/crontabs/pi

# Use supervisord to start all processes
supervisord -c /etc/supervisor/conf.d/supervisord.conf
