#!/bin/bash
# srcs/requirements/wordpress/tools/wordpress-setup.sh

# Funkcja do logowania
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting WordPress setup..."

# Wczytaj dane z secrets do zmiennych środowiskowych
export WORDPRESS_DB_NAME=$(cat /run/secrets/mysql_database)
export WORDPRESS_DB_USER=$(cat /run/secrets/mysql_user)
export WORDPRESS_DB_PASSWORD=$(cat /run/secrets/mysql_password)
export WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
export WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
export WORDPRESS_DB_HOST="mariadb"

log "Database credentials loaded from secrets"
log "Database: $WORDPRESS_DB_NAME, User: $WORDPRESS_DB_USER, Host: $WORDPRESS_DB_HOST"

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
    
    # Czekaj na bazę danych z timeout (używaj danych z secrets)
    log "Waiting for MariaDB to be ready..."
    counter=0
    max_tries=30
    until mysql -h "$WORDPRESS_DB_HOST" -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; do
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
    
    # Konfiguruj WordPress - NOWA METODA z automatycznym tworzeniem wp-config.php
    log "Configuring WordPress..."
    
    # Najpierw spróbuj WP-CLI
    if wp core config \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST:3306" \
        --allow-root \
        --path=/var/www/html 2>/dev/null; then
        log "wp-config.php created successfully with WP-CLI"
    else
        # Jeśli WP-CLI się nie udał, utwórz plik ręcznie
        log "WP-CLI failed, creating wp-config.php manually..."
        
        if [ -f "wp-config-sample.php" ]; then
            cp wp-config-sample.php wp-config.php
            
            # Zastąp wartości w pliku
            sed -i "s/database_name_here/$WORDPRESS_DB_NAME/g" wp-config.php
            sed -i "s/username_here/$WORDPRESS_DB_USER/g" wp-config.php  
            sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/g" wp-config.php
            sed -i "s/localhost/$WORDPRESS_DB_HOST/g" wp-config.php
            
            # Dodaj unikalne klucze bezpieczeństwa
            log "Generating security keys..."
            SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
            if [ -n "$SALT" ]; then
                # Usuń stare klucze i dodaj nowe
                sed -i '/AUTH_KEY\|SECURE_AUTH_KEY\|LOGGED_IN_KEY\|NONCE_KEY\|AUTH_SALT\|SECURE_AUTH_SALT\|LOGGED_IN_SALT\|NONCE_SALT/d' wp-config.php
                sed -i "/\$table_prefix = 'wp_';/i\\$SALT" wp-config.php
            fi
            
            log "wp-config.php created successfully manually"
        else
            log "ERROR: wp-config-sample.php not found!"
            exit 1
        fi
    fi
    
    # Sprawdź czy baza danych istnieje, jeśli nie - zainstaluj WordPress
    if ! wp core is-installed --allow-root --path=/var/www/html; then
        log "Installing WordPress..."
        wp core install \
            --url=${DOMAIN_NAME} \
            --title="My WordPress Site" \
            --admin_user=${WP_ADMIN_USER} \
            --admin_password="$WP_ADMIN_PASSWORD" \
            --admin_email=${WP_ADMIN_EMAIL} \
            --allow-root \
            --path=/var/www/html
        
        # Utwórz dodatkowego użytkownika
        log "Creating additional user..."
        wp user create ${WP_USER} ${WP_USER_EMAIL} \
            --user_pass="$WP_USER_PASSWORD" \
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