#!/bin/bash

# this script deploys wordpress on a fresh debian based server

username=""
userpassword=""

read -p "Enter desired user name: " username
read -p "Enter desired password: " userpassword

domain=${username}.ca

# prepare required packages

sudo apt update
sudo apt install mysql-server php php-mysql libapache2-mod-php -y


# set up databases

echo "Setting up databases..."

sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by '$userpassword';"

sudo mysql_secure_installation --password=$userpassword <<END
n
n
y
y
y
y
END

sudo mysql --password=$userpassword -e "create database wpdb_$username; create user 'wpdb-user'@'%' identified with mysql_native_password BY '$userpassword'; grant all on wpdb_$username.* to 'wpdb-user'@'%';"


# set up apache

echo "Setting up Apache..."

sudo mkdir /var/www/html/$domain
sudo chown -R $USER:$USER /var/www/html/$domain

sudo bash -c "cat <<END > /etc/apache2/sites-available/$domain.conf
<VirtualHost *:80> 
    ServerName $domain
    ServerAlias www.$domain
    ServerAdmin webmaster@$domain
    DocumentRoot /var/www/html/$domain
    ErrorLog ${APACHE_LOG_DIR}/error.log 
    CustomLog ${APACHE_LOG_DIR}/access.log combined 
</VirtualHost> 
END"

sudo a2dissite 000-default
sudo a2ensite $domain
sudo systemctl reload apache2.service


# set up wordpress

echo "Setting up WordPress..."

cd /var/www/html/$domain
wget https://en-ca.wordpress.org/latest-en_CA.tar.gz 
tar xvf latest-en_CA.tar.gz
cd wordpress
mv wp-config-sample.php wp-config.php
sed "s/database_name_here/wpdb_$username/; s/username_here/wpdb-user/; s/password_here/$userpassword/" -i wp-config.php

echo "LAMP setup complete. Access <IP_ADDRESS>/wordpress in a browser or set up a hosts file on the target system."
