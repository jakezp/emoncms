#!/bin/bash

# Start MySQL Server
mysqld_safe > /dev/null 2>&1 & 

RET=1
while [[ RET -ne 0 ]]; do
  echo "Waiting for MySQL to start..."
  sleep 5
  mysql -e "status" > /dev/null 2>&1
  RET=$?
done

# Initialize the db and create the user
echo "CREATE DATABASE emoncms;" >> init.sql
echo "CREATE USER 'emoncms'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';" >> init.sql
echo "GRANT ALL ON emoncms.* TO 'emoncms'@'localhost';" >> init.sql
echo "flush privileges;" >> init.sql
mysql < init.sql

# Cleanup
rm init.sql

# Kill mysql
sleep 10
killall -9 mysqld_safe > /dev/null 2>&1
kill -9 $(ps aux | grep mysqld | grep -v grep | awk -F " " '{print $2}') > /dev/null 2>&1
kill -9 $(ps aux | grep mysql | grep -v grep | awk -F " " '{print $2}') > /dev/null 2>&1

