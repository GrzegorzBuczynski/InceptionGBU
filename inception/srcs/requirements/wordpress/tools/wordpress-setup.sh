#!/bin/bash
# srcs/requirements/wordpress/tools/wordpress-setup.sh

# Exit immediately if a command exits with a non-zero status. This is crucial for reliability.
set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WordPress: $1"
}

log "Starting WordPress setup..."

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

        sed -i '93i\
        if (isset($_SERVER['\''HTTP_HOST'\''])) {\
        $protocol = (!empty($_SERVER['\''HTTPS'\'']) && $_SERVER['\''HTTPS'\''] !== '\''off'\'') ? '\''https://'\'' : '\''http://'\'';\
        define('\''WP_HOME'\'', $protocol . $_SERVER['\''HTTP_HOST'\'']);\
        define('\''WP_SITEURL'\'', $protocol . $_SERVER['\''HTTP_HOST'\'']);\
        }' wp-config.php
        log "wp-config.php created"

   
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


exec "$@"