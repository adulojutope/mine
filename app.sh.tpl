#!/bin/bash
yum update -y

# Mount EFS (same share the bootstrap host uses)
mkdir -p /var/www/html
echo "${efs_dns}:/ /var/www/html nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
mount -a -t nfs4

# Apache + PHP 7.4
yum install -y httpd httpd-tools mod_ssl
amazon-linux-extras enable php7.4
yum clean metadata
yum install -y php php-common php-pear
yum install -y php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip}

# Wait (up to 10 min) for the bootstrap host to finish writing WordPress to EFS
for i in $(seq 1 60); do
  [ -f /var/www/html/wp-config.php ] && break
  sleep 10
done

systemctl enable httpd
systemctl restart httpd