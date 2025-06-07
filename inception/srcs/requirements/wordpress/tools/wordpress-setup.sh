#!/bin/bash
# srcs/requirements/wordpress/tools/wordpress-setup.sh

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WordPress: $1"
}

log "Starting WordPress setup..."

# Load secrets into environment variables
export WORDPRESS_DB_NAME=$(cat /run/secrets/mysql_database)
export WORDPRESS_DB_USER=$(cat /run/secrets/mysql_user)
export WORDPRESS_DB_PASSWORD=$(cat /run/secrets/mysql_password)
export WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
export WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
export WORDPRESS_DB_HOST="mariadb"

log "Database credentials loaded from secrets."
log "Database: $WORDPRESS_DB_NAME, User: $WORDPRESS_DB_USER, Host: $WORDPRESS_DB_HOST"

# Check if WordPress is already installed by looking for wp-config.php
if [ ! -f "/var/www/html/wp-config.php" ]; then
    log "WordPress not found, proceeding with installation..."

    # Download and extract WordPress
    log "Downloading WordPress core..."
    curl -O https://wordpress.org/latest.tar.gz
    tar xzf latest.tar.gz
    cp -r wordpress/* .
    rm -rf wordpress latest.tar.gz

    # Download and install WP-CLI
    log "Downloading WP-CLI..."
    curl -o wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

    # Wait for the database to become available
    log "Waiting for MariaDB to be ready..."
    max_tries=30
    counter=0
    until wp db check --allow-root > /dev/null 2>&1; do
        counter=$((counter + 1))
        if [ $counter -eq $max_tries ]; then
            log "ERROR: Could not connect to MariaDB after $max_tries attempts. Exiting."
            exit 1
        fi
        log "Attempt $counter/$max_tries: Waiting for MariaDB..."
        sleep 2
    done
    log "MariaDB is ready!"

    # Create wp-config.php
    log "Configuring WordPress (creating wp-config.php)..."
    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --allow-root

    # Install WordPress core
    log "Installing WordPress core..."
    wp core install \
        --url=${DOMAIN_NAME} \
        --title="Inception" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root

    # Create an additional user
    log "Creating additional user..."
    wp user create ${WP_USER} ${WP_USER_EMAIL} \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root

    log "WordPress installation completed successfully!"
else
    log "WordPress is already configured. Skipping installation."
fi

# Set correct file permissions
chown -R www-data:www-data /var/www/html

log "Starting PHP-FPM..."
# Execute the main container command (CMD)
exec "$@"
