#!/bin/bash
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
echo welcome > index.html
sudo cp index.html /var/www/html
