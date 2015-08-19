#!/bin/bash
if [[ ${PHP_VERSION} == "5.2" ]]; then
  PHP_VERSION=5.2.17
elif [[ ${PHP_VERSION} == "5.3" ]]; then
  PHP_VERSION=5.3.29
elif [[ ${PHP_VERSION} == "5.4" ]]; then
  PHP_VERSION=5.4.40
elif [[ ${PHP_VERSION} == "5.5" ]]; then
  PHP_VERSION=5.5.20
elif [[ ${PHP_VERSION} == "5.6" ]]; then
  PHP_VERSION=5.6.4
fi

source /root/.phpbrew/bashrc

PHPBREW_PATH="/root/.phpbrew/"
PHPBREW_PHP_PATH="${PHPBREW_PATH}php/php-${PHP_VERSION}/"

PHP_XDEBUG_INI="${PHPBREW_PHP_PATH}var/db/xdebug.ini"

if [[ ${PHP_XDEBUG} == 0 ]] && [[ -f "${PHP_XDEBUG_INI}" ]]; then
  mv  ${PHP_XDEBUG_INI} ${PHP_XDEBUG_INI}.disabled
elif [[ ${PHP_XDEBUG} == 1 ]] && [[ -f "${PHP_XDEBUG_INI}.disabled" ]]; then
  mv  ${PHP_XDEBUG_INI}.disabled ${PHP_XDEBUG_INI}
fi

phpbrew fpm start php-${PHP_VERSION}

if ! [[ -d "/var/lib/mysql/app" ]] && [[ -d "${SQL_DIR}" ]]; then
  service mysql start
  mysql -uroot -e "create database app;"

  for file in ${SQL_DIR}/*.sql; do
    if [[ -f "${file}" ]]; then
      echo "Importing ${file}..."
      mysql -uroot --max_allowed_packet=1073741824 -f app < ${file}
      echo "Import of ${file} done!"
    fi
  done

  service mysql stop
fi

/usr/bin/supervisord -n