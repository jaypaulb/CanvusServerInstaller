# CanvusServerInstaller
Installation Script for setting up and configuring Canvus Server.

Instructions for use:


login to the server (18.04)
Run the below command from ~

wget  'https://raw.githubusercontent.com/jaypaulb/CanvusServerInstaller/main/CanvusServerInstall.sh' -O CanvusServerInstaller_JP2024.sh

sudo chmod +x CanvusServerInstaller_JP2024.sh

./CanvusServerInstaller_JP2024.sh

The script can be run unsupervised if needed, but this will NOT activate the server or create the SSL certs.
You can either supervise the script and enter the key information at the relevant points or you may preset the 
Local Admin Account Password, 
Canvus Server Activation Key, 
FQDN,
Public IP,
for your system at the beginning of the install file before running the setup.
