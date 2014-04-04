#!/usr/bin/env bash
PHPMYADMINVERSION=$1
SRC_DIR=/usr/local/src

if ! [ -d "$SRC_DIR" ];then
  mkdir -p $SRC_DIR
fi

cd $SRC_DIR
wget -q http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/${PHPMYADMINVERSION}/phpMyAdmin-${PHPMYADMINVERSION}-all-languages.zip/download -O phpmyadmin-${PHPMYADMINVERSION}.zip
unzip -q phpmyadmin-${PHPMYADMINVERSION}.zip
mv phpMyAdmin-${PHPMYADMINVERSION}-all-languages phpMyAdmin
mv /root/phpmyadmin/config.inc.php $SRC_DIR/phpMyAdmin/config.inc.php && chmod 644 $SRC_DIR/phpMyAdmin/config.inc.php
