# Dockerfile for base image for emoncms
FROM ubuntu:18.04

LABEL maintainer="Jakezp <jakezp@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

# Install packages
RUN apt-get update \
    && apt-get -yq install supervisor apache2 mariadb-server mariadb-client \
    php libapache2-mod-php php-mysql php-curl php-pear \
    php-dev php-json git-core redis-server \
    build-essential ufw ntp pwgen \
    libmosquitto-dev gnupg libmcrypt-dev cron \
    && rm -rf /var/lib/apt/lists/*
    
# Install pecl dependencies and add pecl modules to php7 configuration
RUN pear channel-discover pear.swiftmailer.org \
    && pecl install redis swift/swift \
    && printf "\n" | pecl install Mosquitto-alpha \
    && printf "\n" | pecl install mcrypt-1.0.1 \
    && sh -c 'echo "extension=mcrypt.so" >> /etc/php/7.2/apache2/conf.d/mcrypt.ini' \
    && sh -c 'echo "extension=mosquitto.so" > /etc/php/7.2/mods-available/mosquitto.ini' \
    && sh -c 'echo "extension=redis.so" > /etc/php/7.2/mods-available/redis.ini' \
    && phpenmod mosquitto \
    && phpenmod redis

# Set timezone for php
RUN sed -i 's/date.timezone \=/date.timezone \= Africa\/Johannesburg/g' /etc/php/7.2/apache2/php.ini

# Enable modrewrite for Apache2
RUN a2enmod rewrite

# AllowOverride for / and /var/www
RUN sed -i '/<Directory \/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Set a server name for Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Add scripts and configs
ADD my.cnf /root/my.cnf
ADD crontab /root/crontab
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD run.sh /run.sh
ADD db.sh /db.sh
RUN chmod 755 /*.sh

# Create required emoncms feed engine data repositories and log configuration 
RUN mkdir /var/lib/phpfiwa \
    && mkdir /var/lib/phpfina \
    && mkdir /var/lib/phptimeseries \
    && mkdir /var/lib/timestore \
    && mkdir /var/log/emoncms \
    && touch /var/log/emoncms.log \
    && touch /var/log/service-runner.log \ 
    && touch /var/log/cron.log \ 
    &&chmod 666 /var/log/emoncms.log \ 
    && chmod 666 /var/log/service-runner.log \
    && chmod 666 /var/log/cron.log

# Expose them as volumes for mounting by host
VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/lib/phpfiwa", "/var/lib/phpfina", "/var/lib/phptimeseries", "/var/www/html", "/var/spool/cron/crontabs/", "/home/pi"]

EXPOSE 80 3306

WORKDIR /home/pi
CMD ["/run.sh"]
