#!/bin/bash
source /root/.phpbrew/bashrc

phpbrew switch ${PHP_VERSION}
phpbrew fpm start

/usr/bin/supervisord -n