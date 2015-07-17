FROM ubuntu:14.04

MAINTAINER Alexander Schneider "alexander.schneider@jankowfsky.com"

# Upgrade system
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
RUN apt-get update

# Setup system and install tools
RUN echo "initscripts hold" | dpkg --set-selections
RUN apt-get -qqy install libreadline-gplv2-dev libfreetype6 apt-utils dialog postfix
RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN echo 'alias ll="ls -lah --color=auto"' >> /etc/bash.bashrc
RUN apt-get -qqy install passwd supervisor git-core sudo unzip wget curl libfile-slurp-perl libmysql-diff-perl vim net-tools software-properties-common python-software-properties

# Set locale
RUN apt-get -qqy install locales
RUN locale-gen --purge de_DE de_DE.UTF-8
RUN locale-gen --purge en_US en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LC_ALL en_US.UTF-8

# Setup ssh
RUN apt-get -qqy install openssh-server
RUN mkdir -p /var/run/sshd
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
RUN sed -ri 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN echo 'root:root' | chpasswd

# Generate a host key before packing.
RUN service ssh start; service ssh stop

# Create SSL cert
RUN mkdir /root/ssl; \
    openssl genrsa -out /root/ssl/local.key 1024; \
    openssl req -new -key /root/ssl/local.key -out /root/ssl/local.csr -subj "/C=DE/ST=BW/L=FREIBURG/O=Jankowfsky AG/OU=Development/CN=localhost"; \
    openssl x509 -req -days 365 -in /root/ssl/local.csr -signkey /root/ssl/local.key -out /root/ssl/local.crt

# Apache
RUN apt-get -qqy install apache2-mpm-prefork apache2-utils
RUN a2enmod rewrite
RUN a2enmod proxy_fcgi
RUN a2enmod ssl
RUN mkdir /etc/apache2/conf.d/
RUN echo "ServerName localhost" | tee /etc/apache2/conf.d/fqdn
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
ADD conf/apache/000-default /etc/apache2/sites-enabled/000-default.conf

# Mysql
RUN apt-get -qqy install mysql-server mysql-common mysql-client
RUN ln -s /run/mysqld/mysqld.sock /tmp/mysql.sock

# Add latest php version
RUN add-apt-repository ppa:ondrej/apache2
RUN add-apt-repository ppa:ondrej/php5 && apt-get update

# PHP
RUN apt-get -qqy install php5-fpm php5 php5-cli php5-mysql php5-curl php5-dev php5-gd php-pear php-apc php5-xdebug libapache2-mod-php5

# PhpMyAdmin
RUN mysqld & \
    service apache2 start; \
	  sleep 5; \
	  printf y\\n\\n\\n1\\n | apt-get install -qqy phpmyadmin; \
    sleep 15; \
    mysqladmin -u root shutdown
RUN sed -i "0,/\/\/ \$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;/{s#// \$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#\$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#g}" /etc/phpmyadmin/config.inc.php
RUN sed -i "/^[ ]*\$cfg\['Servers'\]\[\$i\]\['host'\]/a\\\$cfg\['Servers'\]\[\$i\]\['hide_db'\] = '(information_schema|performance_schema|phpmyadmin|mysql|test)';" /etc/phpmyadmin/config.inc.php
RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled

# Install ant builder
RUN apt-get -qqy install ant

# Install composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install phpunit
RUN composer global require "phpunit/phpunit=4.1.*"; \
    ln -s /root/.composer/vendor/bin/phpunit /usr/bin/phpunit

# Install ruby
RUN apt-get -y install ruby

# Install sass
RUN gem install sass

# Nodejs + NPM
RUN add-apt-repository ppa:chris-lea/node.js && apt-get update
RUN apt-get install -y nodejs

# Install bower
RUN npm install -g bower

# Install grunt
RUN npm install -g grunt-cli

# Install glub
RUN npm install -g gulp

# Install phpbrew
RUN apt-get update
RUN apt-get build-dep -y --fix-missing php5
RUN apt-get install -y php5 php5-dev php-pear autoconf automake curl build-essential \
    libxslt1-dev re2c libxml2 libxml2-dev php5-cli bison libbz2-dev libreadline-dev \
    libfreetype6 libfreetype6-dev libpng12-0 libpng12-dev libjpeg-dev libjpeg8-dev libjpeg8  libgd-dev libgd3 libxpm4 \
    libssl-dev openssl \
    gettext libgettextpo-dev libgettextpo0 \
    libicu-dev \
    libmhash2 libmhash-dev \
    libmcrypt4 libmcrypt-dev \
    libpcre3-dev libpcre++-dev
RUN wget http://launchpadlibrarian.net/121520545/libbison-dev_2.6.2.dfsg-1_amd64.deb && dpkg -i libbison-dev_2.6.2.dfsg-1_amd64.deb
RUN wget http://launchpadlibrarian.net/121520544/bison_2.6.2.dfsg-1_amd64.deb && dpkg -i bison_2.6.2.dfsg-1_amd64.deb
ADD conf/php/phpbrew /usr/bin/phpbrew
RUN chmod +x /usr/bin/phpbrew
ADD conf/php/pbconfig.yaml /tmp/config.yaml
RUN phpbrew init --config=/tmp/config.yaml
RUN echo "source /root/.phpbrew/bashrc" >> /root/.bashrc
RUN ln -s /.phpbrew /root/.phpbrew

ADD conf/php/install_php /usr/bin/install_php
RUN chmod +x /usr/bin/install_php


# Install different php version
ADD conf/php/decoder /root/.phpbrew/modules

# php 5.6
RUN install_php 5.6.4

# php 5.5
RUN install_php 5.5.20

# php 5.4
RUN install_php 5.4.36

# php 5.3
RUN install_php 5.3.29

# php 5.2
#RUN install_php 5.2.17

# Add supervisor config
ADD conf/supervisor/startup.conf /etc/supervisor/conf.d/startup.conf
ENV PHP_VERSION 5.6.4
ENV PHP_XDEBUG 0
ENV SQL_DIR /var/www/_sql

ADD conf/scripts/startup.sh /usr/bin/startup_container
RUN chmod +x /usr/bin/startup_container

# Cleanup
RUN apt-get clean -y; \
    apt-get autoclean -y; \
    apt-get autoremove -y; \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

EXPOSE 22 80 443 3306 9000

CMD ["/bin/bash", "/usr/bin/startup_container"]