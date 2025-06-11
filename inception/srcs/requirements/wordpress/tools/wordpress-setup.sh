#!/bin/bash
# srcs/requirements/wordpress/tools/wordpress-setup.sh

# Exit immediately if a command exits with a non-zero status. This is crucial for reliability.
set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WordPress: $1"
}

log "Starting WordPress setup..."

# --- Step 1: Verify that all required environment variables from .env are set ---
REQUIRED_VARS=(
    "DOMAIN_NAME"
    "WP_ADMIN"
    "WP_ADMIN_EMAIL"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        log "FATAL ERROR: Environment variable ${var} is not set. Please check your srcs/.env file."
        exit 1
    fi
done
# log "All required environment variables are present."

# --- Step 2: Load secrets into environment variables for this script ---
WORDPRESS_DB_NAME=$(cat /run/secrets/mysql_database)
MYSQL_DB_USER=$(cat /run/secrets/mysql_user)
MYSQL_DB_PASSWORD=$(cat /run/secrets/mysql_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
WORDPRESS_DB_HOST="mariadb" # Explicitly add port for clarity


log "Database credentials loaded from secrets."

# --- Step 3: Check if WordPress is already configured ---
if [ ! -f "/var/www/html/wp-config.php" ]; then
    log "wp-config.php not found. Starting first-time installation..."

   # --- Step 3a: Copy WordPress core only if not present ---
    if [ ! -f "/var/www/html/wp-load.php" ]; then
        log "Copying WordPress core to volume..."
        cp -R /tmp/wordpress/* /var/www/html/
        log "WordPress core copied."
    fi

    cp wp-config-sample.php wp-config.php
    


    echo $MYSQL_DB_PASSWORD

    sed -i \
        -e "s/database_name_here/$WORDPRESS_DB_NAME/" \
        -e "s/username_here/$MYSQL_DB_USER/" \
        -e "s/password_here/$MYSQL_DB_PASSWORD/" \
        -e "s/localhost/$WORDPRESS_DB_HOST/" \
        wp-config.php

    # log "Downloading WP-CLI..."
    # curl -o wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar
    # chmod +x wp-cli.phar
    # mv wp-cli.phar /usr/local/bin/wp
    # log "WP-CLI installed successfully."


    # log "Creating admin user '${WP_ADMIN}'..."
    # wp user create "$WP_ADMIN" "$WP_ADMIN_EMAIL" \
    #     --role=administrator \
    #     --user_pass="$WP_ADMIN_PASSWORD" \
    #     --allow-root
    # log "Admin user created."

    # # --- Step 3e: Create an additional user ---
    # log "Creating additional user '${WP_USER}'..."
    # wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
    #     --user_pass="${WP_USER_PASSWORD}" \
    #     --role=author \
    #     --allow-root
    # log "Additional user created."

    # # # NEW: First, check if the hostname 'mariadb' can be resolved
    # log "Resolving hostname 'mariadb'..."
    # if ! getent hosts mariadb; then
    #     log "FATAL ERROR: Could not resolve hostname 'mariadb'. Check network configuration."
    #     exit 1
    # fi
    # log "Hostname 'mariadb' resolved successfully."
    # max_tries=30
    # counter=0
    # # The 'until' loop will now be more reliable due to 'set -e'
    # until wp db check --allow-root > /dev/null 2>&1; do
    #     counter=$((counter + 1))
    #     if [ $counter -ge $max_tries ]; then
    #         log "FATAL ERROR: Could not connect to MariaDB at '$WORDPRESS_DB_HOST' after $max_tries attempts."
    #         log "Please check MariaDB logs and network configuration."
    #         exit 1
    #     fi
    #     log "Attempt $counter/$max_tries: Waiting for MariaDB..."
    #     sleep 2
    # done
    # log "MariaDB is ready! Connection successful."
    
    # # --- Step 3f: Set final permissions ---
    # log "Setting final ownership and permissions..."
    # chown -R www-data:www-data /var/www/html

    # log "WordPress installation completed successfully!"
else
    log "wp-config.php already exists. Skipping installation."
fi

log "Starting PHP-FPM service..."
# Execute the main container command (CMD from Dockerfile)
exec "$@"
