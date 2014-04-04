FROM debian:wheezy

MAINTAINER Alexander Schneider "alexander.schneider@jankowfsky.com"

# Upgrade system
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update;apt-get -y upgrade

# Setup system and install tools
RUN echo "initscripts hold" | dpkg --set-selections
RUN apt-get -qqy install libreadline-gplv2-dev libfreetype6 apt-utils dialog
RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN echo 'alias ll="ls -lah --color=auto"' >> /etc/bash.bashrc
RUN apt-get -qqy install openssh-server passwd supervisor git-core sudo unzip wget curl libfile-slurp-perl libmysql-diff-perl vim locales net-tools
RUN locale-gen --purge de_DE.UTF-8

# Add user
RUN useradd dev -m -s /bin/bash
RUN echo dev:dev | chpasswd
RUN usermod -a -G sudo dev
RUN echo 'dev ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/dev
RUN chmod 0440 /etc/sudoers.d/dev

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
# RUN echo "deb http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list
# RUN echo "deb http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
# RUN echo "deb-src http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list
# RUN wget http://www.dotdeb.org/dotdeb.gpg
# RUN apt-key add dotdeb.gpg
# RUN apt-get update

# PHP
RUN apt-get -qqy install libapache2-mod-php5 php5 php5-cli php5-mysql php5-curl php5-dev php5-gd php-pear

# PhpMyAdmin
RUN mkdir -p /root/phpmyadmin
ADD conf/phpmyadmin/config.inc.php /root/phpmyadmin/config.inc.php
ADD scripts/build_phpmyadmin.sh /root/phpmyadmin/build_phpmyadmin.sh
RUN sh /root/phpmyadmin/build_phpmyadmin.sh 4.1.11
ADD conf/phpmyadmin/phpmyadmin.conf /etc/apache2/conf.d/phpmyadmin.conf

# Add supervisor config
ADD conf/supervisor/debian-lamp.conf /etc/supervisor/conf.d/debian-lamp.conf

EXPOSE 22 80

CMD ["/usr/bin/supervisord", "-n"]