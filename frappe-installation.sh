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
sudo apt-get upgrade -y vim net-tools screen htop 
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




# Install Node.js via NVM
# Add new changes
cd "$DIRECTORY"
sudo apt install -y curl
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
sudo -i -u $FRAPPE_USER bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; nvm install 18'





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
bench --site "$SITE_NAME" install-app erpnext
bench --site "$SITE_NAME" install-app leaf_procurement

# Bench start 
nohup bench start &
sleep 20
ps aux | grep "honcho"


bench --site "$SITE_NAME" migrate






# scripts and directories setup 
cd "$DIRECTORY"
mkdir -p backup/erp.samsons.com 
touch "$DIRECTORY"/scripts/backupsite.sh "$DIRECTORY"/scripts/start_bench.sh logs
sudo chmod +x "$DIRECTORY"/scripts/backupsite.sh "$DIRECTORY"/scripts/start_bench.sh



# add backup script data
sudo tee -a "$DIRECTORY"/scripts/backupsite.sh > /dev/null <<EOL
#!/bin/bash
cd /home/frappe/frappe-bench/sites/
bench --site $SITE_NAME backup --with-files --backup-path "$DIRECTORY"/backup/$SITE_NAME/
EOL

  


# add backup script data
sudo tee -a "$DIRECTORY"/scripts/start_bench.sh > /dev/null <<EOL
#!/bin/bash

cd "$DIRECTORY"/frappe-bench
echo "Bench starting..."
echo "================="
bench start &
sleep 15
echo " "
echo "Active Bench Processes:"
echo "======================="
ps aux | grep "honcho"
EOL


echo "Setup completed, please check the scripts in /home/$USER/scripts/ for backup and start bench operations."