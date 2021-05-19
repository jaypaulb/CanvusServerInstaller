# CanvusServerInstaller
Installation Script for setting up and configuring Canvus Server.

Instructions for use:


login to the server (18.04)
Run the below command from ~

wget  'https://raw.githubusercontent.com/jaypaulb/CanvusServerInstaller/main/canvusinstall.sh' -O CanvusServerInstaller_JP2021.sh

sudo chmod +x CanvusServerInstaller_JP2021.sh

nano CanvusServerInstaller_JP2021.sh

adjust the variable at the top of the script to suite your needs then Ctrl+O to save and Ctrl+X to exit.
Then run the script with

./CanvusServerInstaller_JP2021.sh

On completion you will need to set the external URL in the mt-canvus-server.ini file.

sudo nano /etc/MultiTaction/canvus/mt-canvus-server.ini
