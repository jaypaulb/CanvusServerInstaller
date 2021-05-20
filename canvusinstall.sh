#!/bin/bash
#################
# Change this values
#################


psqluser="CanvusDbUser"   # Database username
psqlpass="CanvusDbPwd"  # Database password
psqldb="CanvusDb"   # Database name
canvuskey="1234-ABCD-9876-ZYXW" # Canvus testing activation key
canvusadmin="admin@domain.com" # Canvus dashboard admin email
latestcanvusinstall="http://linkgoeshere" #link to the latest version of the canvus server install .sh

#################################################
#                       #
#    PLEASE DO NOT CHANGE THE FOLLOWING CODES   #
#                       #
#################################################

#################
# Dependicies
#################
sudo apt-get update
sudo apt-get update
sudo apt-get install postgresql-10 -y


#################
echo # Database
#################
sudo printf "CREATE USER $psqluser WITH PASSWORD '$psqlpass';\nCREATE DATABASE $psqldb WITH OWNER $psqluser;\nGRANT ALL ON DATABASE $psqldb TO $psqluser" > /tmp/jaypaul.sql

sudo -u postgres psql -f /tmp/jaypaul.sql
echo "=========================================="
echo "Finished Database section"


#################
echo # Update Synch Commit
#################
sudo sed -i -e 's/#synchronous_commit = on/synchronous_commit = off/g' /etc/postgresql/10/main/postgresql.conf
echo "=========================================="
echo "Synch Commit Set to Off"

#################
echo # Install Canvus, Cp example ini, update INI with DB details.
#################

wget $latestcanvusinstall -O /tmp/jaypaul-canvus-install.sh
echo "=========================================="
echo " Downloaded canvus install script"

sudo sh /tmp/jaypaul-canvus-install.sh
echo "=========================================="
echo " Installed canvus"

sudo cp /etc/MultiTaction/canvus/mt-canvus-server.ini.example /etc/MultiTaction/canvus/mt-canvus-server.ini
echo "============== Example ini copied to live ini ====================="
echo foo | tee -a "$(tty)" | ls /etc/MultiTaction/canvus/

sudo sed -i.bak '/\[sql\]/a databasename='$psqldb'\nusername='$psqluser'\npassword='$psqlpass'' /etc/MultiTaction/canvus/mt-canvus-server.ini
echo "=========================================="
echo " SQL details added to mt-canvus-server.ini"

/opt/mt-canvus-server/bin/LicenseTool --activate $canvuskey

sudo mkdir -p /etc/MultiTaction/Licenses/ && sudo cp ~/MultiTaction/Licenses/* /etc/MultiTaction/Licenses
echo "=============License files copied to /etc/ location =================="
echo ls /etc/MultiTaction/Licenses/

sudo systemctl start mt-canvus-server
sudo systemctl start mt-canvus-dashboard

echo "==============Waiting for canvus server to become active ===================="
systemctl is-active mt-canvus-server && echo Canvus Server is running

touch canvus_server_admin_details.txt
sudo /opt/mt-canvus-server/bin/mt-canvus-server --create-admin $canvusadmin >> canvus_server_admin_details.txt
echo "Admin login details are saved in canvus_server_admin_details.txt"
echo sudo /opt/mt-canvus-server/bin/mt-canvus-server --list-users

#################
# Cleaning up
#################
echo "Cleaning"
sudo rm -r /tmp/jaypaul*

echo "Cleaned"

echo "End of the script"

exit
