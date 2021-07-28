#!/bin/bash
yum update -y

rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm


yum install -y nginx php56w-fpm php56w-cli php56w-mcrypt php56w-mysql php56w-mbstring php56w-dom git
mkdir -p /var/www/laravel

echo "server {
        listen   80 default_server;
        listen [::]:80 default_server ipv6only=on;

        root /var/www/laravel/public/;
        index index.php index.html index.htm;

        location / {
             try_files \$uri \$uri/ /index.php?\$query_string;
        }

        # pass the PHP scripts to FastCGI server listening on /var/run/php5-fpm.sock
        location ~ \.php$ {
                try_files \$uri /index.php =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)\$;
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include fastcgi_params;
        }
}" | tee /etc/nginx/conf.d/laravel.conf
sed -i 's/80 default_server/80/g' /etc/nginx/nginx.conf
if `grep "cgi.fix_pathinfo" /etc/php.ini` ; then
  sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini
else
  sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini
fi
#sudo php5enmod mcrypt
systemctl restart php-fpm
systemctl restart nginx
if [ ! -e /usr/local/bin/composer ]
then
  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer
  chmod +x /usr/local/bin/composer
fi
git clone https://github.com/ideadevice/quickstart-basic.git /var/www/laravel
sed -i 's/DB_HOST=.*/DB_HOST=@@{DBService.address}@@/' /var/www/laravel/.env
#if [ "@@{calm_array_index}@@" == "0" ]; then
sudo su - -c "cd /var/www/laravel; composer install ; php artisan migrate"
#fi
chown -R nginx:nginx /var/www/laravel
chmod -R 777 /var/www/laravel/
systemctl restart nginx
firewall-cmd --add-service=http --zone=public --permanent
firewall-cmd --reload
