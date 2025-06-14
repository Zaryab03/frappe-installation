#!/bin/bash
set -e

echo "Server Configuration Setup has started..."
echo "==========================="

# Variables
MYSQL_ROOT_PASSWORD="mariadb@123"
FRAPPE_USER="frappe"
DIRECTORY="/home/$FRAPPE_USER"
SITE_NAME="erp.abc.com"
DB_NAME="db01"
ADMIN_PASS="ERP@123456"

cd "$DIRECTORY"

# Install required packages
sudo apt-get update -y
sudo apt-get upgrade -y vim net-tools
sudo apt-get install -y git
sudo apt-get install -y python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils
sudo apt-get install -y python3.10-venv
sudo apt-get install -y software-properties-common
sudo apt-get install -y mariadb-server mariadb-client
sudo apt-get install -y redis-server
sudo apt-get install -y xvfb libfontconfig wkhtmltopdf
sudo apt-get install -y libmysqlclient-dev


# Secure MariaDB installation automatically

sudo mysql -u root <<EOF
-- Set root password and authentication method
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely (comment out next line if you want remote root access)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database and access to it
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

echo "===================================================="
echo "MariaDB secure installation completed automatically."




# Add recommended configuration to /etc/mysql/my.cnf automatically
sudo tee -a /etc/mysql/my.cnf > /dev/null <<EOL

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOL
sudo service mysql restart




# Install npm, yarn, and frappe-bench
sudo apt-get install -y npm
sudo npm install -g yarn
sudo pip3 install frappe-bench




# Initialize bench
bench init --frappe-branch version-15 frappe-bench
sudo chmod -R o+rx "$DIRECTORY"




cd "$DIRECTORY"/frappe-bench/sites



# Create new site (manual password entry required)
bench new-site --db-name "$DB_NAME" --admin-password "$ADMIN_PASS" "$SITE_NAME" --db-root-password "$MYSQL_ROOT_PASSWORD" 



cd ../apps/
bench get-app --branch version-15 https://github.com/sowaan/erpnext.git
bench get-app --branch main https://github.com/sowaan/leaf_procurement.git 
cd ../sites/
bench use erp.abc.com
bench --site "$SITE_NAME" install-app erpnext
bench --site "$SITE_NAME" install-app leaf_procurement

# Bench start 
bench start &

bench --site "$SITE_NAME" migrate --skip-failing



# scripts and directories setup 
cd "$DIRECTORY"
mkdir -p backup/erp.samsons.com logs
cd "$DIRECTORY"/scripts
touch backupsite.sh start_bench.sh
sudo chmod +x backupsite.sh start_bench.sh



# add backup script data
sudo tee -a backupsite.sh > /dev/null <<EOL
#!/bin/bash
cd /home/frappe/frappe-bench/sites/
bench --site $SITE_NAME backup --with-files --backup-path "$DIRECTORY"/backup/$SITE_NAME/
EOL

  


# add backup script data
sudo tee -a start_bench.sh > /dev/null <<EOL
#!/bin/bash
sleep 6

# Load NVM manually (critical!)
export NVM_DIR="/home/frappe/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Activate Node.js 18
nvm use 18

echo " "
echo "ERP STATUS - $(date)"
echo " "

cd /home/frappe/frappe-bench1

#Checking node version
node --version

echo " "
echo "Bench starting..."
echo "================="
bench start &
EOL

timedatectl set-timezone Asia/Karachi

# Nginx installation
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Install and configure Certbot for SSL 
sudo apt install mkcert -y
mkcert -install

# Install and configure Avahi for mDNS
sudo apt install -y avahi-daemon
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

echo " ======================================================================================================="
echo "Setup completed, please check the scripts in /home/$USER/scripts/ for backup and start bench operations."