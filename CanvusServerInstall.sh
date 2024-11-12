#!/bin/bash

VERSION=0.51

set +e

#### Pre-Config Option - Change these if you plan to run this unsupervised - we recommend supervised installs. ####
ADMIN_EMAIL="admin@local.local"  # Update this to your email address if you want a live admin account rather than a local-only admin.
ADMIN_PASSWORD_DEFAULT="Taction123!"  # Update this if you want a specific admin password, or change it after the first login.
FQDN_DEFAULT=""  # Update this if you want to get Let's Encrypt auto-renewal SSL certs and configure them for use with this server.
LETS_ENCRYPT_EMAIL="mt-canvus-server-setup-script@multitaction.com"  # This allows us to track what servers have been deployed with this script.  Feel free to change this if you like, however it must be a valid email address to work.
ACTIVATION_KEY_DEFAULT="xxxx-xxxx-xxxx-xxxx"  # Update this if you have a specific activation key. If not the server won't activate but all the other steps will still work.

# Check if FQDN is all lowercase
if [[ "$FQDN_DEFAULT" =~ [A-Z] ]]; then
  echo "FQDN contains uppercase characters, converting to lowercase..."
  FQDN_DEFAULT=$(echo "$FQDN_DEFAULT" | tr '[:upper:]' '[:lower:]')
fi

# Function to check if a step is already completed
function is_step_completed() {
  local step_name="$1"
  local validation_command="$2"
  if eval "$validation_command" &>/dev/null; then
    echo "$step_name already completed, skipping..."
    return 0
  else
    return 1
  fi
}

# Update package lists and install curl and gnupg in one go to reduce updates
is_step_completed "Update packages" "dpkg -s curl gnupg postgresql" || {
  echo "Updating package lists and installing curl, gnupg, and postgresql..."
apt-get update
apt-get install -y curl gnupg postgresql
}

# Add MultiTaction repository if not already added
REPO_FILE="/etc/apt/sources.list.d/mt-software-stable.list"
REPO_LINE="deb http://update.multitouch.fi/aptly/bionic multitaction stable"

is_step_completed "Add MultiTaction repository" "grep -Fxq '$REPO_LINE' '$REPO_FILE'" || {
  echo "Adding MultiTaction repository..."
  echo "$REPO_LINE" >> "$REPO_FILE"
  # Add the GPG key only if the repository was added
  if ! apt-key list | grep -q "MultiTouch Ltd"; then
    echo "Adding MultiTouch GPG key..."
    curl -s http://update.multitouch.fi/apt.key | apt-key add -
  fi
  # Update package lists after adding the repository
  apt-get update
}

# Install mt-canvus-server3
is_step_completed "Install mt-canvus-server3" "dpkg -s mt-canvus-server3" || {
  echo "Installing mt-canvus-server3..."
apt-get install -y mt-canvus-server3
}

# Configure the database for mt-canvus-server3
INI_FILE="/etc/MultiTaction/canvus/mt-canvus-server.ini"
is_step_completed "Configure mt-canvus-server3 database" "grep -q 'databasename=' '$INI_FILE'" || {
  echo "Configuring the database for mt-canvus-server3..."
/opt/mt-canvus-server/bin/mt-canvus-server --configure-db

# Verify that the database configuration was successful
if grep -q "databasename=" "$INI_FILE"; then
  echo "Database configuration successful."
else
  echo "Error: Database configuration failed." >&2
  echo "Continuing despite error."
fi
}

# Enable and start mt-canvus-server and mt-canvus-dashboard services
for service in mt-canvus-server mt-canvus-dashboard; do
  is_step_completed "Enable and start $service" "systemctl is-active --quiet $service" || {
    echo "Enabling and starting $service..."
    systemctl enable "$service"
    systemctl start "$service"
    echo "Waiting for $service to fully start..."
    sleep 5  # Adding a delay to ensure the service is fully ready
  }
done

# Check if admin user already exists
is_step_completed "Check if admin user exists" "/opt/mt-canvus-server/bin/mt-canvus-server --list-users | grep -q '$ADMIN_EMAIL'" && ADMIN_EXISTS=true || ADMIN_EXISTS=false

# Check if activation key already exists
is_step_completed "Check if activation key exists" "[ -f '/var/lib/mt-canvus-server/MultiTaction/Licenses/.cslicense' ]" && ACTIVATION_EXISTS=true || ACTIVATION_EXISTS=false

# Prompt for admin password with timeout and verification
if [ "$ADMIN_EXISTS" = false ]; then
  while true; do
    ADMIN_PASSWORD=${ADMIN_PASSWORD_DEFAULT}
    echo "You have 15 seconds to enter your desired admin password (min 8 characters, min 1 number, min 1 special character) [default: $ADMIN_PASSWORD_DEFAULT]: "
    read -t 15 -r USER_PASSWORD_INPUT
    ADMIN_PASSWORD=${USER_PASSWORD_INPUT:-$ADMIN_PASSWORD}

    # Prompt for verification only if a custom password is entered
    if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_DEFAULT" ]; then
      read -p "Please re-enter your admin password for verification: " ADMIN_PASSWORD_VERIFY
      echo
      if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_VERIFY" ]; then
        break
      else
        echo "Passwords do not match. Please try again."
      fi
    else
      break
    fi
  done
  # Create a default admin user
  echo "Creating admin user..."
  /opt/mt-canvus-server/bin/mt-canvus-server --create-admin "$ADMIN_EMAIL" "$ADMIN_PASSWORD" || echo "Warning: Admin user creation failed, continuing..."
else
  echo "Admin user already exists, skipping admin user creation."
fi

# Prompt for activation key with timeout
if [ "$ACTIVATION_EXISTS" = false ]; then
  echo "You have 15 seconds to enter your activation key (4 sets of 4 characters separated by a dash) [default: $ACTIVATION_KEY_DEFAULT]: "
  read -t 15 -r USER_ACTIVATION_KEY_INPUT
  ACTIVATION_KEY=${USER_ACTIVATION_KEY_INPUT:-$ACTIVATION_KEY_DEFAULT}

  echo "Activating the software..."
/opt/mt-canvus-server/bin/mt-canvus-server --activate "$ACTIVATION_KEY" || echo "Warning: Activation failed, continuing..."
else
  echo "Activation key already exists, skipping activation."
fi

# Check if SSL certificate already exists
CERT_PATH="/etc/letsencrypt/live/$FQDN"
if [ -d "$CERT_PATH" ] && [ -f "$CERT_PATH/fullchain.pem" ] && [ -f "$CERT_PATH/privkey.pem" ]; then
  echo "SSL certificate already exists, skipping SSL acquisition steps."
  # Debug: Test reading the certificate files as mt-canvus-server user
  MT_CERT_PATH="/var/lib/mt-canvus-server/certs"
  sudo -u mt-canvus-server cat "$MT_CERT_PATH/certificate.pem" && echo "Canvus server user can read certificate.pem" || echo "Error: Canvus server user cannot read certificate.pem"
  sudo -u mt-canvus-server cat "$MT_CERT_PATH/certificate-key.pem" && echo "Canvus server user can read certificate-key.pem" || echo "Error: Canvus server user cannot read certificate-key.pem"
  if sudo -u mt-canvus-server cat "$MT_CERT_PATH/certificate.pem" && sudo -u mt-canvus-server cat "$MT_CERT_PATH/certificate-key.pem"; then
    echo "Certificates are accessible. Skipping steps until restarting mt-canvus-server service."
  else
    echo "Certificates are not accessible as expected. Proceeding with SSL setup."
  fi
else
  
  # Stop services before SSL configuration
  echo "Stopping mt-canvus-server and mt-canvus-dashboard services before SSL configuration..."
  for service in mt-canvus-server mt-canvus-dashboard; do
    systemctl stop "$service"
  done

  # Get public IP address and prompt for DNS confirmation
  PUBLIC_IP=$(curl -s ifconfig.me)
  echo "This is the public IP of this server: $PUBLIC_IP"
  echo "Please ensure your domain DNS settings are pointing to this IP and have propagated before proceeding!"
  read -p "Press Enter to continue once DNS settings have propagated."

  # Prompt for fully qualified domain name (FQDN) with timeout
  FQDN=${FQDN_DEFAULT}
  echo "You have 15 seconds to enter the fully qualified domain name (FQDN) for this server (enter or wait to skip SSL cert setup): [default: $FQDN_DEFAULT]"
  read -t 15 -r USER_FQDN_INPUT
  FQDN=${USER_FQDN_INPUT:-$FQDN}

  # Convert FQDN to lowercase if necessary
  if [[ "$FQDN" =~ [A-Z] ]]; then
    echo "FQDN contains uppercase characters, converting to lowercase..."
    FQDN=$(echo "$FQDN" | tr '[:upper:]' '[:lower:]')
  fi

  if [ -z "$FQDN" ]; then
    echo "No FQDN entered, skipping SSL setup."
    exit 0
  fi

  # Verify that the FQDN resolves to the public IP
  while true; do
    RESOLVED_IP=$(dig +short "$FQDN")
    if [ "$RESOLVED_IP" = "$PUBLIC_IP" ]; then
      echo "FQDN '$FQDN' successfully resolves to the correct IP address: $RESOLVED_IP."
      break
    else
      echo "FQDN '$FQDN' failed to resolve to this server. Please re-enter FQDN or press enter to retry: (the same FQDN will be used again if you wait 15 seconds.)"
      read -t 15 -r NEW_FQDN
      FQDN=${NEW_FQDN:-$FQDN}
    fi
  done

# Obtain SSL certificates using Let's Encrypt certbot
  is_step_completed "Install certbot" "dpkg -s certbot" || {
    echo "Installing certbot..."
  apt-get install -y certbot
  }

  echo "Obtaining SSL certificates for FQDN '$FQDN'..."
  certbot certonly --standalone -d "$FQDN" --agree-tos --non-interactive --email "$LETS_ENCRYPT_EMAIL" --no-eff-email

  # Check if certificate was successfully obtained
  CERT_PATH="/etc/letsencrypt/live/$FQDN"

  # Debugging info: print the CERT_PATH value
  echo "Checking for certificates at: $CERT_PATH"

  if [ -d "$CERT_PATH" ] && [ -f "$CERT_PATH/fullchain.pem" ] && [ -f "$CERT_PATH/privkey.pem" ]; then
    echo "SSL certificate generation successful."
  else
    echo "Error: SSL certificate generation failed. Exiting."
    exit 1
  fi

  # Create certificate directory if it doesn't exist
  MT_CERT_PATH="/var/lib/mt-canvus-server/certs"
  echo "Creating certificate directory if it doesn't exist..."
  mkdir -p "$MT_CERT_PATH"

# Create a new group for certificate access and add mt-canvus-server user to it
  echo "Creating ssl-cert-access group and adding mt-canvus-server to it..."
  groupadd -f ssl-cert-access
  usermod -a -G ssl-cert-access mt-canvus-server

# Change group ownership for Let's Encrypt directories and certificate files
  echo "Changing group ownership for Let's Encrypt directories and certificate files..."
  chgrp -R ssl-cert-access /etc/letsencrypt
  chmod -R g+rx /etc/letsencrypt
  chmod -R g+r /etc/letsencrypt/archive/$FQDN/*

# Create symbolic links for the certificates using absolute paths

  # Debug: Print contents of the certificate path
  ls -l "$CERT_PATH"

  # Debug: Check for any existing certificates in the MT_CERT_PATH before creating symlinks
  ls -l "$MT_CERT_PATH"
  ln -sf "$CERT_PATH/fullchain.pem" "$MT_CERT_PATH/certificate.pem"
  echo "Created symlink: $MT_CERT_PATH/certificate.pem -> $CERT_PATH/fullchain.pem"

  ln -sf "$CERT_PATH/privkey.pem" "$MT_CERT_PATH/certificate-key.pem"
  echo "Created symlink: $MT_CERT_PATH/certificate-key.pem -> $CERT_PATH/privkey.pem"

  ln -sf "$CERT_PATH/chain.pem" "$MT_CERT_PATH/certificate-chain.pem"
  echo "Created symlink: $MT_CERT_PATH/certificate-chain.pem -> $CERT_PATH/chain.pem"

  # Update mt-canvus-server.ini with SSL configuration
  echo "Updating mt-canvus-server.ini with SSL configuration..."
  sed -i "s|^; external-url=.*|external-url=https://$FQDN|" "$INI_FILE"
  echo "Updated 'external-url' to 'https://$FQDN' in $INI_FILE"

  sed -i "s|^; ssl-enabled=.*|ssl-enabled=true|" "$INI_FILE"
  echo "Updated 'ssl-enabled' to 'true' in $INI_FILE"

  sed -i "s|^; certificate-file=.*|certificate-file=$MT_CERT_PATH/certificate.pem|" "$INI_FILE"
  echo "Updated 'certificate-file' to '$MT_CERT_PATH/certificate.pem' in $INI_FILE"

  sed -i "s|^; certificate-key-file=.*|certificate-key-file=$MT_CERT_PATH/certificate-key.pem|" "$INI_FILE"
  echo "Updated 'certificate-key-file' to '$MT_CERT_PATH/certificate-key.pem' in $INI_FILE"

  sed -i "s|^; certificate-chain-file=.*|certificate-chain-file=$MT_CERT_PATH/certificate-chain.pem|" "$INI_FILE"
  echo "Updated 'certificate-chain-file' to '$MT_CERT_PATH/certificate-chain.pem' in $INI_FILE"

  # Set permissions to ensure mt-canvus-server can read the certificates
  echo "Setting permissions to ensure mt-canvus-server can read the certificates..."
  chown -R mt-canvus-server:ssl-cert-access "$MT_CERT_PATH"
  chmod 640 "$MT_CERT_PATH"/*
fi

# Restart the mt-canvus-server service to apply group changes
echo "Restarting mt-canvus-server service to apply group changes..."
systemctl restart mt-canvus-server.service

# Debug: Test reading the certificate files as mt-canvus-server user
sudo -u mt-canvus-server cat "$MT_CERT_PATH/certificate.pem" && echo "Canvus server user can read certificate.pem" || echo "Error: Canvus server user cannot read certificate.pem"
sudo -u mt-canvus-server cat "$MT_CERT_PATH/certificate-key.pem" && echo "Canvus server user can read certificate-key.pem" || echo "Error: Canvus server user cannot read certificate-key.pem"

# Start mt-canvus-dashboard service again (already restarted server above)
echo "Starting mt-canvus-dashboard service again..."
systemctl start mt-canvus-dashboard.service

# Reload the SSL certs to verify that MT-Canvus-Server has access to them and all permissions have worked.
echo "Reloading SSL certificates for mt-canvus-server..."
/opt/mt-canvus-server/bin/mt-canvus-server --reload-certs