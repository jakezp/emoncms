# Emoncms with mqtt input configured

Emoncms is a powerful open-source web-app for processing, logging and visualizing energy, temperature and other environmental data. 
Emoncms with mqtt_input configured

***Run with:***
```
docker run -d --name='emoncms-mqtt' --net='bridge' \
          -e 'MYSQL_PASSWORD'='password' \
          -e 'MQTT_HOST'='host_ip' \
          -e 'MQTT_PORT'='1883' \
          -e 'MQTT_USER'='username' \
          -e 'MQTT_PASS'='password' \
          -e 'EMAIL_TO'='to_address@example.com' \
          -e 'EMAIL_FROM'='from_address@example.com' \
          -e 'EMAIL_HOST'='smtp.example.com' \
          -e 'EMAIL_PORT'='25' \
          -e 'EMAIL_NAME'='EmonCMS Notifications' \
          -e 'EMAIL_ENCRYPT'='tls' \
          -e 'EMAIL_USER'='email_username' \
          -e 'EMAIL_PASS'='email_password' \
          -p '8080:80/tcp' \
          -v '/tmp/emoncms/etc/mysql':'/etc/mysql' \
          -v '/tmp/emoncms/mysql':'/var/lib/mysql' \
          -v '/tmp/emoncms/phpfiwa':'/var/lib/phpfiwa' \
          -v '/tmp/emoncms/phpfina':'/var/lib/phpfina' \
          -v '/tmp/emoncms/phptimeseries':'/var/lib/phptimeseries' \
          -v '/tmp/emoncms/html':'/var/www/html' \
          -v '/tmp/emoncms/crontabs':'/var/spool/cron/crontabs' \
          -v '/etc/localtime':'/etc/localtime':'ro' \
          jakezp/emoncms
```
***Change:*** <br/>
              **MYSQL_PASSWORD** - MySQL password<br/>
              **MQTT_HOST** - MQTT hostname or IP (If MQTT_HOST is not specified, MQTT support will not be enabled)<br/>
              **MQTT_PORT** - Optional. If not specified, 1883 will be configured.<br/>
              **MQTT_USER** - Optional. If not specified, it will be left blank.<br/>
              **MQTT_PASS** - Optional. If not specified, it will be left blank.<br/>
              **EMAIL_TO** - To address - Required if EMAIL_FROM and EMAIL_HOST are specified. <br/>
              **EMAIL_FROM** - If EMAIL_FROM and EMAIL_HOST is not specified, SMTP will be disabled.<br/>
              **EMAIL_HOST** - If EMAIL_FROM and EMAIL_HOST is not specified, SMTP will be disabled.<br/>
              **EMAIL_PORT** - 25, 465 or 587 - Required if EMAIL_FROM and EMAIL_HOST are specified. <br/>
              **EMAIL_NAME** - From name - Optional.<br/>
              **EMAIL_ENCRYPT** - ssl, tls - Optional. Will be disabled if not specified.<br/>
              **EMAIL_USER** - SMTP server username - Optional. Will be disabled if not specified.<br/>
              **EMAIL_PASS** - SMTP server password - Optional. Will be disabled if not specified.<br/>
              **/tmp/emoncms** - preferred location on the host
