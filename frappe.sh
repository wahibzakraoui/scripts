#!/bin/bash

# Prompt for user input
read -p "Enter the UNIX username to use: " username
read -p "Enter the site name: " sitename
read -s -p "Enter the MySQL root password: " mysql_password
echo
read -p "Enter the latest Frappe branch version (e.g., v14.39.0): " frappe_branch
read -p "Enter the latest ERPNext branch version (e.g., v14.27.1): " erpnext_branch

# Update and upgrade packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Add user and grant sudo privileges
sudo adduser $username
sudo usermod -aG sudo $username

# Switch to the user's home directory
cd /home/$username

# Install necessary packages
sudo apt-get install -y git
sudo apt-get install -y python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils
sudo apt-get install -y python3.10-venv
sudo apt-get install -y software-properties-common
sudo apt-get install -y mariadb-server mariadb-client
sudo apt-get install -y redis-server
sudo apt-get install -y xvfb libfontconfig wkhtmltopdf
sudo apt-get install -y libmysqlclient-dev

# Secure MySQL installation
sudo mysql_secure_installation <<EOF
$mysql_password
Y
Y
Y
Y
N
Y
EOF

# Configure MySQL
sudo sh -c 'echo -e "[mysqld]\ncharacter-set-client-handshake = FALSE\ncharacter-set-server = utf8mb4\ncollation-server = utf8mb4_unicode_ci\n[mysql]\ndefault-character-set = utf8mb4" >> /etc/mysql/my.cnf'
sudo service mysql restart

# Install additional dependencies
sudo apt-get install -y curl
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
source ~/.profile
nvm install 18.16.0
sudo apt-get install -y npm
sudo npm install -g yarn
sudo pip3 install frappe-bench

# Initialize Frappe Bench with specified branch versions
bench init --frappe-branch $frappe_branch frappe-bench
cd frappe-bench

# Grant permissions
chmod -R o+rx /home/$username

# Create new site
bench new-site $sitename

# Install apps
bench get-app payments
bench get-app --branch $erpnext_branch erpnext
bench get-app hrms
bench --site $sitename install-app erpnext
bench --site $sitename install-app hrms
