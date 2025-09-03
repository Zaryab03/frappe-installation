# frappe-installation
Frappe installation script

Make sure to execute these commands before executing this script.

sudo -i
adduser frappe
usermod -aG sudo frappe
su frappe
cd /home/frappe
sudo apt install curl
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
source ~/.profile
nvm install 18
