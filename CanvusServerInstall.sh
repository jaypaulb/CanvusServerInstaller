#!/bin/bash

#################
# Change this values
#################
#uncomment to debug

psqluser="canvus"   # Database username
psqlpass="multimulti"  # Database password
psqldb="canvusdb"   # Database name
canvuskey="aaaa-bbbb-cccc-dddd" # Canvus testing activation key
canvusadmin="admin@admin.com" # Canvus dashboard admin email
latestcanvusinstall="https://canvus-downloads.s3.amazonaws.com/packages/mt-canvus-server-3.0.0-build28929-Ubuntu-18.04-amd64.sh" #link to the latest version of the canvus server install .sh
domain="example.com"  #external domain name for ssl cert and server functions



#################################################
#                                               #
#    PLEASE DO NOT CHANGE THE FOLLOWING CODE    #
#                                               #
#################################################
certificates="$HOME/MultiTaction/canvus/server/certificates/LetsEncrypt"
cert="$HOME/MultiTaction/canvus/server/certificates/LetsEncrypt/live/$domain/cert.pem"
key="$HOME/MultiTaction/canvus/server/certificates/LetsEncrypt/live/$domain/privkey.pem"
chain="$HOME/MultiTaction/canvus/server/certificates/LetsEncrypt/live/$domain/fullchain.pem"


#################
# Dependicies
#################
sudo apt-get update
sudo apt-get install postgresql-10 -y
sudo snap install --classic certbot

#################
# LetsEncrypt Certs
#################

# Create LetsEncrypt paths
sudo certbot install

# Configure LetsEncrypt Certbot to stop Canvus Server + Dashboard before renewing certs to release port 80.
sudo sh -c 'printf "#!/bin/sh\nservice mt-canvus-server stop\n" > /etc/letsencrypt/renewal-hooks/pre/mt-canvus-server.sh'
sudo chmod 755 /etc/letsencrypt/renewal-hooks/pre/mt-canvus-server.sh
sudo sh -c 'printf "#!/bin/sh\nservice mt-canvus-dashboard stop\n" > /etc/letsencrypt/renewal-hooks/pre/mt-canvus-dashboard.sh'
sudo chmod 755 /etc/letsencrypt/renewal-hooks/pre/mt-canvus-dashboard.sh

# Depreciated I found a better way to do this using the LetsEncryt config file
# # Configure LetsEncrypt Certbot to deploy the certificates Canvus Readable Location.
# sudo domain=$domain sh -c 'printf "#!/bin/sh\n 
# echo "Letsencrypt deploy hook running..."\n
# echo "RENEWED_DOMAINS=$RENEWED_DOMAINS"\n
# echo "RENEWED_LINEAGE=$RENEWED_LINEAGE"\n
# if grep --quiet "$domain" <<< "$RENEWED_DOMAINS"; then\n
  # > /etc/MultiTaction/canvus/server/certificates/LetsEncrypt/$domain.cert.pem\n
  # > /etc/MultiTaction/canvus/server/certificates/LetsEncrypt/$domain.key.pem\n
  # > /etc/MultiTaction/canvus/server/certificates/LetsEncrypt/$domain.fullchain.pem\n
  # cat $RENEWED_LINEAGE/cert.pem > /etc/MultiTaction/canvus/server/certificates/LetsEncrypt/$domain.cert.pem\n
  # cat $RENEWED_LINEAGE/privkey.pem > /etc/MultiTaction/canvus/server/certificates/LetsEncrypt/$domain.key.pem\n
  # cat $RENEWED_LINEAGE/fullchain.pem > /etc/MultiTaction/canvus/server/certificates/LetsEncrypt/$domain.fullchain.pem\n
  # echo "Canvus cert, key and fullchain updated and postfix restarted"\n
# fi" > /etc/letsencrypt/renewal-hooks/deploy/mt-canvus-server.sh'
# sudo chmod 755 /etc/letsencrypt/renewal-hooks/deploy/mt-canvus-server.sh

# Configure LetsEncrypt Certbot to start Canvus Server + Dashboard after renewing.
sudo sh -c 'printf "#!/bin/sh\nservice mt-canvus-server start\n" > /etc/letsencrypt/renewal-hooks/post/mt-canvus-server.sh'
sudo chmod 755 /etc/letsencrypt/renewal-hooks/post/mt-canvus-server.sh
sudo sh -c 'printf "#!/bin/sh\nservice mt-canvus-dashboard start\n" > /etc/letsencrypt/renewal-hooks/post/mt-canvus-dashboard.sh'
sudo chmod 755 /etc/letsencrypt/renewal-hooks/post/mt-canvus-dashboard.sh

echo "======= Pre, Deploy and Post Cert Scripts in place ======="
echo "ls /etc/letsencrypt/renewal-hooks/pre/=" 
ls /etc/letsencrypt/renewal-hooks/pre/
echo "ls /etc/letsencrypt/renewal-hooks/deploy/=" 
ls /etc/letsencrypt/renewal-hooks/deploy/
echo "ls /etc/letsencrypt/renewal-hooks/post/=" 
ls /etc/letsencrypt/renewal-hooks/post/

#Get The Certs!
sudo certbot certonly --noninteractive --agree-tos --cert-name $domain -d $domain --register-unsafely-without-email --standalone

#set -x
#trap read debug

# Mv the Certs to Canvus Folder and patch the config file so renewals work.
mkdir -p "$certificates"/archive/
echo "========= Canvus Archive Certs Folder Created =============="
sudo mv /etc/letsencrypt/archive/$domain "$certificates"/archive
echo "========= Canvus Certs moved from LetsEncrypt folder =============="
ls +R "$certificates"/archive/
sudo sed -i "s,/etc/letsencrypt/archive/$domain,$certificates/archive/$domain," /etc/letsencrypt/renewal/$domain.conf
echo "========= New Canvus Specific Archive Cert Location added to LetEncrypt Renewal Scripts =============="
cat /etc/letsencrypt/renewal/$domain.conf
echo "======================="
mkdir -p "$certificates"/live/
echo "========= Canvus Live Certs Folder Created =============="
sudo mv /etc/letsencrypt/live/$domain/ "$certificates"/live/$domain/
echo "========= Canvus Live Certs moved from LetsEncrypt folder =============="
sudo sed -i "s,/etc/letsencrypt/live/$domain,$certificates/live/$domain," /etc/letsencrypt/renewal/$domain.conf
echo "========= New Canvus Specific Live Cert Location added to LetEncrypt Renewal Scripts =============="
cat /etc/letsencrypt/renewal/$domain.conf
echo "======================="
sudo chmod -R 0777 "$certificates"/
ls -l -R $certificates
sudo certbot update_symlinks

#################
# Database
#################
sudo printf "CREATE USER $psqluser WITH PASSWORD '$psqlpass';\nCREATE DATABASE $psqldb WITH OWNER $psqluser;\nGRANT ALL ON DATABASE $psqldb TO $psqluser" > /tmp/jaypaul.sql

sudo -u postgres psql -f /tmp/jaypaul.sql

# sudo -u postgres psql -c "grant all on database $psqldb to $psqluser;"
echo "=========================================="
echo "Finished Database section"


#################
# Update Synch Commit
#################
sudo sed -i -e 's/#synchronous_commit = on/synchronous_commit = off/g' /etc/postgresql/10/main/postgresql.conf
echo "Synch Commit Set to Off"

#################
# Install Canvus, Cp example ini, update INI with DB details.
#################

wget $latestcanvusinstall -O /tmp/jaypaul-canvus-install.sh
echo "=========================================="
echo " Downloaded canvus install script"

sudo sh /tmp/jaypaul-canvus-install.sh
echo "=========================================="
echo " Installed canvus"

sudo cp /etc/MultiTaction/canvus/mt-canvus-server.ini.example /etc/MultiTaction/canvus/mt-canvus-server.ini
echo "============== Example ini copied to live ini ====================="
echo "ls /etc/MultiTaction/canvus/=" 
ls -R /etc/MultiTaction/canvus/

sudo sed -i.bak_url '/external-url=/a external-url=https://'$domain'  \n#added by install script' /etc/MultiTaction/canvus/mt-canvus-server.ini
echo "=========================================="
echo " Domain Details added to mt-canvus-server.ini"

sudo sed -i.bak_db '/\[sql\]/a databasename='$psqldb'\nusername='$psqluser'\npassword='$psqlpass'\n #added by install script' /etc/MultiTaction/canvus/mt-canvus-server.ini
echo "=========================================="
echo " SQL details added to mt-canvus-server.ini"

sudo sed -i.bak_cert '/certificate-file=/a certificate-file='$cert'  \n#added by install script' /etc/MultiTaction/canvus/mt-canvus-server.ini
echo "=========================================="
echo " Cert.pem added to mt-canvus-server.ini"

sudo sed -i.bak_key '/certificate-key-file=/a certificate-key-file='$key'  \n#added by install script' /etc/MultiTaction/canvus/mt-canvus-server.ini
echo "=========================================="
echo " privkey.pem added to mt-canvus-server.ini"

sudo sed -i.bak_chain '/certificate-chain-file=/a certificate-chain-file='$chain'  \n#added by install script' /etc/MultiTaction/canvus/mt-canvus-server.ini
echo "=========================================="
echo " chain.pem added to mt-canvus-server.ini"

/opt/mt-canvus-server/bin/LicenseTool --activate $canvuskey

sudo mkdir -p /etc/MultiTaction/Licenses/ && sudo cp ~/MultiTaction/Licenses/* /etc/MultiTaction/Licenses
echo "=============License files copied to /etc/ location =================="
echo "ls /etc/MultiTaction/Licenses/=" 
ls /etc/MultiTaction/Licenses/

sudo systemctl start mt-canvus-server
sudo systemctl start mt-canvus-dashboard

echo "==============Waiting for canvus server to become active ===================="
sleep 10
systemctl is-active mt-canvus-server && echo Canvus Server is running


touch canvus_server_admin_details.txt
sudo /opt/mt-canvus-server/bin/mt-canvus-server --create-admin $canvusadmin >> canvus_server_admin_details.txt
echo "Admin login details are saved in canvus_server_admin_details.txt"
cat canvus_server_admin_details.txt
echo | sudo /opt/mt-canvus-server/bin/mt-canvus-server --list-users

#################
# Cleaning up
#################
echo "Cleaning"
sudo rm -r /tmp/jaypaul*

echo "Cleaned"

echo "End of the script"

exit
