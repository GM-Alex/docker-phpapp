FROM ubuntu:latest

MAINTAINER Alexander Schneider "alexander.schneider@jankowfsky.com"

# Upgrade system
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update # && apt-get -y upgrade

# Setup system and install tools
RUN echo "initscripts hold" | dpkg --set-selections
RUN apt-get -qqy install libreadline-gplv2-dev libfreetype6 apt-utils dialog
RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN echo 'alias ll="ls -lah --color=auto"' >> /etc/bash.bashrc
RUN apt-get -qqy install openssh-server passwd supervisor git-core sudo unzip wget curl libfile-slurp-perl libmysql-diff-perl vim locales net-tools python-software-properties
RUN locale-gen --purge de_DE.UTF-8

# Add user
RUN echo 'root:root' | chpasswd

# Configure git
ADD conf/git/.gitconfig /home/dev/.gitconfig

RUN mkdir -p /var/run/sshd && mkdir /home/dev/.ssh && chmod 700 /home/dev/.ssh

# Generate a host key before packing.
RUN service ssh start; service ssh stop

# Apache
RUN apt-get -qqy install apache2-mpm-prefork apache2-utils
RUN a2enmod rewrite
RUN echo "ServerName localhost" | tee /etc/apache2/conf.d/fqdn
ADD conf/apache/000-default /etc/apache2/sites-enabled/000-default

# Mysql
RUN apt-get -qqy install mysql-server mysql-common mysql-client
RUN service mysql start;mysqladmin -uroot password root;service mysql stop

# Add latest php version
RUN add-apt-repository ppa:ondrej/php5 && apt-get update

# PHP
RUN apt-get -qqy install libapache2-mod-php5 php5 php5-cli php5-mysql php5-curl php5-dev php5-gd php-pear php-apc php5-xdebug

# Setup xdebug
RUN echo "xdebug.remote_enable=1" >> /etc/php5/mods-available/xdebug.ini
RUN echo "xdebug.remote_autostart=0" >> /etc/php5/mods-available/xdebug.ini
RUN echo "xdebug.remote_connect_back=1" >> /etc/php5/mods-available/xdebug.ini
RUN echo "xdebug.remote_port=9000" >> /etc/php5/mods-available/xdebug.ini

# PhpMyAdmin
RUN mysqld & \
    service apache2 start; \
    sleep 5; \
    printf y\\n\\n\\n1\\n | apt-get install -y phpmyadmin; \
    sleep 15; \
    mysqladmin -u root shutdown

RUN sed -i "0,/\/\/ \$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;/{s#// \$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#\$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#g}" /etc/phpmyadmin/config.inc.php
RUN sed -i "/^[ ]*\$cfg\['Servers'\]\[\$i\]\['host'\]/a\\\$cfg\['Servers'\]\[\$i\]\['hide_db'\] = '(information_schema|performance_schema|phpmyadmin|mysql|test)';" /etc/phpmyadmin/config.inc.php
RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled

# Install composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install phpunit
RUN pear config-set auto_discover 1 && pear install pear.phpunit.de/PHPUnit

# Install ruby
RUN apt-get -y install ruby rubygems

# Install sass
RUN gem install sass

# Nodejs + NPM
RUN add-apt-repository ppa:chris-lea/node.js && apt-get update
RUN apt-get install -y nodejs

# Install bower
RUN npm install -g bower

# Add supervisor config
ADD conf/supervisor/debian-lamp.conf /etc/supervisor/conf.d/debian-lamp.conf

EXPOSE 22 80

CMD ["/usr/bin/supervisord", "-n"]