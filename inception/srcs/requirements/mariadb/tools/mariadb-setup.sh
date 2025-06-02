#!/bin/bash
# srcs/requirements/mariadb/tools/mariadb-setup.sh

# Funkcja do logowania
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] MariaDB: $1"
}

log "Starting MariaDB setup..."

# Sprawdź czy baza danych nie jest już zainicjowana
if [ ! -f "/var/lib/mysql/.wordpress_initialized" ]; then
    log "Initializing MariaDB database..."
    
    # Inicjalizuj bazę danych
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --rpm
    
    log "Starting temporary MariaDB instance for setup..."
    
    # Uruchom tymczasową instancję MariaDB w tle
    mysqld --user=mysql --skip-networking --socket=/tmp/mysql_temp.sock &
    MYSQL_PID=$!
    
    # Czekaj na uruchomienie
    for i in {1..30}; do
        if mysql --socket=/tmp/mysql_temp.sock -e "SELECT 1" >/dev/null 2>&1; then
            log "Temporary MariaDB instance is ready"
            break
        fi
        log "Waiting for temporary MariaDB instance... ($i/30)"
        sleep 1
    done
    
    log "Configuring database and users..."
    
    # Skonfiguruj bazę danych i użytkowników
    mysql --socket=/tmp/mysql_temp.sock << EOF
USE mysql;
FLUSH PRIVILEGES;

-- Ustaw hasło root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Usuń anonimowych użytkowników
DELETE FROM mysql.user WHERE User='';

-- Usuń test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Utwórz bazę danych WordPress
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Utwórz użytkownika WordPress
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Aplikuj zmiany
FLUSH PRIVILEGES;
EOF

    # Zatrzymaj tymczasową instancję
    log "Stopping temporary MariaDB instance..."
    kill $MYSQL_PID
    wait $MYSQL_PID 2>/dev/null
    
    log "MariaDB setup completed!"
else
    log "MariaDB already initialized"
fi

# Oznacz jako zainicjowane
touch /var/lib/mysql/.wordpress_initialized

log "Starting MariaDB server..."
exec "$@"

#chmod +x inception/srcs/requirements/mariadb/tools/mariadb-setup.sh