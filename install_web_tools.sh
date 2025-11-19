yum update -y

yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Server ready to comunicate with DB</h1>" > /var/www/html/index.html

yum install -y mysql