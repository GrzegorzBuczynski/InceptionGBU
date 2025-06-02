#!/bin/bash
# srcs/requirements/wordpress/tools/wordpress-setup.sh

# Funkcja do logowania
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting WordPress setup..."

# Sprawdź czy WordPress już nie jest zainstalowany
if [ ! -f "/var/www/html/wp-config.php" ]; then
    log "WordPress not found, installing..."
    
    # Pobierz WordPress
    log "Downloading WordPress..."
    curl -O https://wordpress.org/latest.tar.gz
    tar xzf latest.tar.gz
    
    # Skopiuj pliki WordPress (bezpieczniej niż mv)
    log "Copying WordPress files..."
    cp -r wordpress/* .
    rm -rf wordpress latest.tar.gz
    
    # Pobierz WP-CLI
    log "Downloading WP-CLI..."
    curl -o wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    
    # Czekaj na bazę danych z timeout
    log "Waiting for MariaDB to be ready..."
    counter=0
    max_tries=30
    
    until mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1" > /dev/null 2>&1; do
        counter=$((counter + 1))
        if [ $counter -eq $max_tries ]; then
            log "ERROR: Could not connect to MariaDB after $max_tries attempts"
            exit 1
        fi
        log "Attempt $counter/$max_tries: Waiting for MariaDB..."
        sleep 2
    done
    
    log "MariaDB is ready!"
    
    # Ustaw właściciela plików
    chown -R www-data:www-data /var/www/html
    
    # Konfiguruj WordPress
    log "Configuring WordPress..."
    wp core config \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb:3306 \
        --allow-root \
        --path=/var/www/html
    
    # Sprawdź czy baza danych istnieje, jeśli nie - zainstaluj WordPress
    if ! wp core is-installed --allow-root --path=/var/www/html; then
        log "Installing WordPress..."
        wp core install \
            --url=${DOMAIN_NAME} \
            --title="My WordPress Site" \
            --admin_user=${WP_ADMIN_USER} \
            --admin_password=${WP_ADMIN_PASSWORD} \
            --admin_email=${WP_ADMIN_EMAIL} \
            --allow-root \
            --path=/var/www/html
        
        # Utwórz dodatkowego użytkownika
        log "Creating additional user..."
        wp user create ${WP_USER} ${WP_USER_EMAIL} \
            --user_pass=${WP_USER_PASSWORD} \
            --allow-root \
            --path=/var/www/html
        
        log "WordPress installation completed!"
    else
        log "WordPress is already installed."
    fi
    
    # Ustaw właściciela plików ponownie
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
else
    log "WordPress configuration already exists."
fi

log "Starting PHP-FPM..."
exec "$@"