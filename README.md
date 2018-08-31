# Emoncms with mqtt input configured

Emoncms is a powerful open-source web-app for processing, logging and visualizing energy, temperature and other environmental data. 
Emoncms with mqtt_input configured

Run with:

```
docker run -d --name='emoncms-mqtt' --net='bridge' \
          -e 'MYSQL_PASSWORD'='password' \
          -e 'MQTT_HOST'='host_ip' \
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
***Change:*** <br>
              **MYSQL_PASSWORD** - MySQL password<br>
              **MQTT_HOST** - MQTT hostname or IP (If MQTT_HOST is not specified, MQTT support will not be enabled)<br>
              **/tmp/emoncms** - preferred location on the host
