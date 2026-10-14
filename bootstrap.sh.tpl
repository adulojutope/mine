#!/bin/bash

# 1. Mount EFS (retry until the mount target is reachable, stop if it never is)
yum update -y
yum install -y nfs-utils
mkdir -p /var/www/html
for i in $(seq 1 30); do
  mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns}:/ /var/www/html && break
  sleep 10
done
mountpoint -q /var/www/html || { echo "EFS mount failed" >&2; exit 1; }
echo "${efs_dns}:/ /var/www/html nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

# 2. Apache
yum install -y httpd httpd-tools
systemctl enable httpd
systemctl start httpd

# 3. PHP 7.4
amazon-linux-extras enable php7.4
yum clean metadata
yum install -y php php-common php-pear
yum install -y php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip}

# 4. WordPress (only if not already on EFS)
if [ ! -f /var/www/html/wp-config.php ]; then
  cd /tmp
  wget https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  cp -r wordpress/* /var/www/html/
  cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

  # 5. Database settings from Terraform
  sed -i "s|database_name_here|${db_name}|" /var/www/html/wp-config.php
  sed -i "s|username_here|${db_user}|"      /var/www/html/wp-config.php
  sed -i "s|password_here|${db_password}|"  /var/www/html/wp-config.php
  sed -i "s|localhost|${db_host}|"          /var/www/html/wp-config.php

  # 6. Tell WordPress the site is HTTPS (the ALB terminates TLS)
  sed -i "/^<?php/a if ((\$_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https') { \$_SERVER['HTTPS'] = 'on'; }" /var/www/html/wp-config.php

  # 7. Real security keys instead of the placeholders
  if curl -sf https://api.wordpress.org/secret-key/1.1/salt/ -o /tmp/salts.txt; then
    sed -i "/put your unique phrase here/d" /var/www/html/wp-config.php
    sed -i "/^define( 'DB_COLLATE'/r /tmp/salts.txt" /var/www/html/wp-config.php
  fi
fi

# 8. Permissions (after WordPress exists)
usermod -a -G apache ec2-user
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 2775 {} \;
find /var/www/html -type f -exec chmod 0664 {} \;

systemctl restart httpd
