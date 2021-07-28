#!/bin/bash
set -ex

yum update -y
platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1`

if [ $platform_version -eq 7 ];then
  if [ "@@{DBService.MYSQL_VERSION}@@" == "5.5" ];then
    mysql_repo_package="http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm"
  elif [ "@@{DBService.MYSQL_VERSION}@@" == "5.6" ];then
  
mysql_repo_package="http://repo.mysql.com/mysql-community-release-el7.rpm"
  elif [ "@@{DBService.MYSQL_VERSION}@@" == "5.7" ];then
    mysql_repo_package="https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm"
  fi
else
  echo "Version Not supported"
fi

yum install -y $mysql_repo_package
yum update -y

yum install -y mysql-community-server.x86_64

/bin/systemctl start mysqld

#Mysql secure installation
mysql -u root<<-EOF
UPDATE mysql.user SET Password=PASSWORD('@@{DBService.MYSQL_PASSWORD}@@') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
EOF

firewall-cmd --add-service=mysql --permanent
firewall-cmd --reload

mysql -u root -p"@@{DBService.MYSQL_PASSWORD}@@"<<-EOF
CREATE DATABASE homestead;
GRANT ALL PRIVILEGES ON homestead.* TO 'homestead'@'%' identified by 'secret';
FLUSH PRIVILEGES;
EOF
