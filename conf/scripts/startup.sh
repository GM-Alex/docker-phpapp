#!/bin/bash
source /root/.phpbrew/bashrc

phpbrew fpm start php-${PHP_VERSION}

/usr/bin/supervisord -n