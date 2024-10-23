# CanvusServerInstaller
Installation Script for setting up and configuring Canvus Server.

Instructions for use:


login to the server (18.04)
Run the below command from ~

wget  'https://raw.githubusercontent.com/jaypaulb/CanvusServerInstaller/main/CanvusServerInstall.sh' -O CanvusServerInstaller_JP2021.sh

sudo chmod +x CanvusServerInstaller_JP2021.sh

nano CanvusServerInstaller_JP2021.sh

adjust the variable at the top of the script to suit your needs then Ctrl+O to save and Ctrl+X to exit.
Then run the script with

./CanvusServerInstaller_JP2021.sh

Please note that this will provide you with the admin password as plain text on completion.  Do Not Run Unsupervised.  This is the ONLY time the admin password will be presented.
