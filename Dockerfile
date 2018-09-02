# Dockerfile for base image for emoncms
FROM ubuntu:latest

MAINTAINER jakezp

ENV DEBIAN_FRONTEND noninteractive

# Install packages
RUN apt-get update
RUN apt-get -yq install supervisor apache2 mariadb-server mariadb-client php libapache2-mod-php php-mysql php-curl php-pear \
    php-dev php-json git-core redis-server build-essential ufw ntp pwgen libmosquitto-dev gnupg libmcrypt-dev cron

# Install pecl dependencies
RUN pear channel-discover pear.swiftmailer.org
RUN pecl install redis swift/swift
RUN printf "\n" | pecl install Mosquitto-alpha
RUN printf "\n" | pecl install mcrypt-1.0.1

# Add pecl modules to php7 configuration
RUN sh -c 'echo "extension=mcrypt.so" >> /etc/php/7.2/apache2/conf.d/mcrypt.ini'
RUN sh -c 'echo "extension=mosquitto.so" > /etc/php/7.2/mods-available/mosquitto.ini'
RUN sh -c 'echo "extension=redis.so" > /etc/php/7.2/mods-available/redis.ini'
RUN phpenmod mosquitto
RUN phpenmod redis

# Set timezone for php
RUN sed -i 's/date.timezone \=/date.timezone \= Africa\/Johannesburg/g' /etc/php/7.2/apache2/php.ini

# Enable modrewrite for Apache2
RUN a2enmod rewrite

# AllowOverride for / and /var/www
RUN sed -i '/<Directory \/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Set a server name for Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Add db setup script
ADD run.sh /run.sh
ADD db.sh /db.sh
RUN chmod 755 /*.sh

# MySQL config
ADD my.cnf /root/my.cnf

# Add cron for emailreport
ADD crontab /root/crontab

# Add supervisord configuration file
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create required data repositories for emoncms feed engine
RUN mkdir /var/lib/phpfiwa
RUN mkdir /var/lib/phpfina
RUN mkdir /var/lib/phptimeseries
RUN mkdir /var/lib/timestore

# Create log directories & files
RUN mkdir /var/log/emoncms
RUN touch /var/log/emoncms.log
RUN touch /var/log/service-runner.log
RUN touch /var/log/cron.log
RUN chmod 666 /var/log/emoncms.log
RUN chmod 666 /var/log/service-runner.log
RUN chmod 666 /var/log/cron.log

# Expose them as volumes for mounting by host
VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/lib/phpfiwa", "/var/lib/phpfina", "/var/lib/phptimeseries", "/var/www/html", "/var/spool/cron/crontabs/", "/home/pi"]

EXPOSE 80 3306

WORKDIR /home/pi
CMD ["/run.sh"]
