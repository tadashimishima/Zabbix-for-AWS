#!/bin/sh

sudo su -
wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.0.1/zabbix-3.0.1.tar.gz
tar xvzf zabbix-3.0.1.tar.gz 
groupadd zabbix
useradd -g zabbix zabbix
cd zabbix-3.0.1
yum install -y gcc mysql56-devel libxml2-devel net-snmp-devel libcurl-devel
./configure --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2
make install
sed -i 's/# DBPassword=/DBPassword=zabbix/g'  /usr/local/etc/zabbix_server.conf
yum install -y httpd24 php56 mysql55-server php56-mysqlnd
service httpd start
chkconfig httpd on
groupadd www
usermod -a -G www ec2-user
usermod -a -G www apache
chown -R root:www /var/www
chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;
service mysqld start
chkconfig mysqld on
mkdir /var/www/html/zabbix
cp -a frontends/php/* /var/www/html/zabbix/
chown root:www /var/www/html/zabbix/conf
chmod g+w /var/www/html/zabbix/conf
yum install -y php56-mbstring php56-bcmath php56-gd httpd24 php56 mysql55-server php56-mysqlnd
sed -i 's/post_max_size = 8M/post_max_size = 16M/g'  /etc/php-5.6.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g'  /etc/php-5.6.ini
sed -i 's/max_input_time = 60/max_input_time = 300/g'  /etc/php-5.6.ini
sed -i 's|;date.timezone =|date.timezone = "Asia/Tokyo"|g'  /etc/php-5.6.ini
sed -i 's/;always_populate_raw_post_data/always_populate_raw_post_data/g'  /etc/php-5.6.ini
service httpd restart
mysql -u root << END
create database zabbix;
grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix' with grant option;
END
mysql -u root zabbix < database/mysql/schema.sql  
mysql -u root zabbix < database/mysql/images.sql 
mysql -u root zabbix < database/mysql/data.sql 
zabbix_server
zabbix_agentd

