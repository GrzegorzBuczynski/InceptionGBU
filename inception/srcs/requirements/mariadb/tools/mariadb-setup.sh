#!/bin/bash
# srcs/requirements/mariadb/tools/mariadb-setup.sh
# Exit immediately if a command exits with a non-zero status.
set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] MariaDB: $1"
}

# Function to read secrets from files
read_secret() {
    local secret_name=$1
    local secret_file="/run/secrets/$secret_name"
    if [ -f "$secret_file" ]; then
        cat "$secret_file"
    else
        log "Error: Secret $secret_name not found in $secret_file" >&2
        exit 1
    fi
}

# Use proper file path for marker
MARKER_FILE="/var/lib/mysql/.initialized"

# Read secrets from files
MYSQL_ROOT_PASSWORD=$(read_secret "mysql_root_password")
MYSQL_DATABASE=$(read_secret "mysql_database")
MYSQL_USER=$(read_secret "mysql_user")
MYSQL_PASSWORD=$(read_secret "mysql_password")

# Check if all required secrets were loaded
if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    log "Error: Not all required secrets were loaded"
    exit 1
fi

log "Secrets loaded successfully"

# Check if MariaDB system tables are initialized
if [ ! -f "$MARKER_FILE" ]; then
    log "Starting MariaDB setup..."
    
    # Install and initialize the MariaDB database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start the MySQL service
    mysqld --user=mysql --datadir=/var/lib/mysql &
    
    log "Waiting for MariaDB to start..."
    for i in $(seq 1 30); do
        if mysqladmin ping --silent 2>/dev/null; then
            log "MariaDB is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            log "Error: MariaDB failed to start within 30 seconds"
            exit 1
        fi
        sleep 1
    done
    
    # Secure root user
    log "Securing root user..."
    mysql -uroot -e "DROP USER IF EXISTS 'root'@'%';"
    mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    log "Root user secured - only localhost access allowed"
    
    # Create marker file for system initialization
    touch "$MARKER_FILE"
    log "MariaDB system initialization complete"
    
    # Stop the MySQL service
    mysqladmin shutdown -uroot -p"$MYSQL_ROOT_PASSWORD"
    
else
    log "MariaDB system already initialized"
fi

# Always check if the database exists (independent of system initialization)
log "Checking if database '$MYSQL_DATABASE' exists..."

# Start MariaDB to check/create database
mysqld --user=mysql --datadir=/var/lib/mysql &

log "Waiting for MariaDB to start..."
for i in $(seq 1 30); do
    if mysqladmin ping --silent 2>/dev/null; then
        log "MariaDB is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        log "Error: MariaDB failed to start within 30 seconds"
        exit 1
    fi
    sleep 1
done

# Check if the database exists
if [ -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    log "Database '$MYSQL_DATABASE' already exists"
else
    log "Creating database '$MYSQL_DATABASE' and user '$MYSQL_USER'..."
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE \`$MYSQL_DATABASE\`;"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    log "Database '$MYSQL_DATABASE' and user '$MYSQL_USER' created successfully"
fi

# Stop the MySQL service
mysqladmin shutdown -uroot -p"$MYSQL_ROOT_PASSWORD"

# Execute any additional commands passed to the script
exec "$@"