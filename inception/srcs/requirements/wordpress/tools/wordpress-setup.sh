#!/bin/bash
# srcs/requirements/wordpress/tools/wordpress-setup.sh

# Exit immediately if a command exits with a non-zero status. This is crucial for reliability.
set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WordPress: $1"
}

log "Starting WordPress setup..."

# Verify that all required environment variables from .env are set ---
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

# Load secrets into environment variables for this script ---
WORDPRESS_DB_NAME=$(cat /run/secrets/mysql_database)
MYSQL_DB_USER=$(cat /run/secrets/mysql_user)
MYSQL_DB_PASSWORD=$(cat /run/secrets/mysql_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
WORDPRESS_DB_HOST="mariadb" # Explicitly add port for clarity


log "Database credentials loaded from secrets."

# Check if WordPress is already configured ---
if [ ! -f "/var/www/html/wp-config.php" ]; then
    log "wp-config.php not found. Starting first-time installation..."


    if ! command -v wp &> /dev/null; then
        log "Downloading WP-CLI..."
        curl -o wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
        log "WP-CLI installed successfully."
    else
        log "wp-cli already installed"
    fi

    if [ ! -f "/var/www/html/wp-load.php" ]; then
        log "Downloading WordPress core..."
        wp core download --path=/var/www/html --allow-root
        log "WordPress core downloaded to /var/www/html"
    fi

    # Creating wp-config.php
    if [ ! -f wp-config.php ]; then
        echo "Creating wp-config.php..."
        wp config create \
            --dbname="$WORDPRESS_DB_NAME" \
            --dbuser="$MYSQL_DB_USER" \
            --dbpass="$MYSQL_DB_PASSWORD" \
            --dbhost="$WORDPRESS_DB_HOST" \
            --skip-check \
            --allow-root

        # # Forcing domain and https
        # echo "define('WP_HOME', 'https://${DOMAIN_NAME}');" >> wp-config.php
        # echo "define('WP_SITEURL', 'https://${DOMAIN_NAME}');" >> wp-config.php

        # opcional alternative aproach
        #         wp-config.php
        echo "if (isset(\$_SERVER['HTTP_HOST'])) {" >> wp-config.php
        echo "  \$protocol = (!empty(\$_SERVER['HTTPS']) && \$_SERVER['HTTPS'] !== 'off') ? 'https://' : 'http://';" >> wp-config.php
        echo "  define('WP_HOME', \$protocol . \$_SERVER['HTTP_HOST']);" >> wp-config.php
        echo "  define('WP_SITEURL', \$protocol . \$_SERVER['HTTP_HOST']);" >> wp-config.php
        echo "}" >> wp-config.php

    fi
    echo "error_log('HTTP_HOST: ' . \$_SERVER['HTTP_HOST']);"  >> wp-config.php

    log "Waiting on database $WORDPRESS_DB_HOST..."
    until wp db check --allow-root > /dev/null 2>&1; do
        sleep 2
    done
    # Install WordPress
    if ! wp core is-installed --allow-root; then
        echo "Instaluję WordPress..."
        wp core install \
            --url="https://${DOMAIN_NAME}" \
            --title="${SITE_TITLE}" \
            --admin_user="$WP_ADMIN" \
            --admin_password="$WP_ADMIN_PASSWORD" \
            --admin_email="$WP_ADMIN_EMAIL" \
            --skip-email \
            --allow-root

        # Add regular user
        wp user create "$WP_USER" "$WP_USER_EMAIL" \
            --user_pass="$WP_USER_PASSWORD" \
            --role=author \
            --allow-root
    fi
else
    log "wp-config.php already exists. Skipping installation."
fi

wp option update siteurl "https://gbuczyns.42.fr" --allow-root
wp option update home "https://gbuczyns.42.fr" --allow-root

wp rewrite flush --allow-root
wp search-replace 'https://gbuczyns.42.fr' 'https://192.168.1.100' --all-tables --allow-root

log "Starting PHP-FPM service..."
# Execute the main container command (CMD from Dockerfile)
exec "$@"


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


    # log "Copying wp-config.php..."
    # cp wp-config-sample.php wp-config.php
    # log "Setting up wp-config.php..."
    # sed -i \
    #     -e "s/database_name_here/$WORDPRESS_DB_NAME/" \
    #     -e "s/username_here/$MYSQL_DB_USER/" \
    #     -e "s/password_here/$MYSQL_DB_PASSWORD/" \
    #     -e "s/localhost/$WORDPRESS_DB_HOST/" \
    #     wp-config.php