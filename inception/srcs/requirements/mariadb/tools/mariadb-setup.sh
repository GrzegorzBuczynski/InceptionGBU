#!/bin/bash
# srcs/requirements/mariadb/tools/mariadb-setup.sh

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] MariaDB: $1"
}

log "Starting MariaDB setup..."

# Load secrets into variables
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
MYSQL_DATABASE=$(cat /run/secrets/mysql_database)
MYSQL_USER=$(cat /run/secrets/mysql_user)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)

# Check if the data directory is empty before initializing
if [ ! -d "/var/lib/mysql/mysql" ]; then
    log "Data directory is empty. Initializing MariaDB database..."

    # Initialize the database system
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --rpm

    log "Starting temporary MariaDB instance for setup..."

    # Start a temporary MariaDB instance in the background
    mysqld_safe --user=mysql --skip-networking --socket=/tmp/mysql_temp.sock &
    MYSQL_PID=$!

    # Wait for the instance to be ready
    for i in {1..30}; do
        if mysqladmin ping --socket=/tmp/mysql_temp.sock >/dev/null 2>&1; then
            log "Temporary MariaDB instance is ready."
            break
        fi
        log "Waiting for temporary MariaDB instance... ($i/30)"
        sleep 1
    done

    log "Configuring database and users..."

    # Configure the database and users using SQL commands
    mysql --socket=/tmp/mysql_temp.sock << EOF
USE mysql;
FLUSH PRIVILEGES;

-- Set the root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Remove anonymous users for security
DELETE FROM mysql.user WHERE User='';

-- Remove the test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Create the WordPress database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create the WordPress user
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Apply all changes
FLUSH PRIVILEGES;
EOF

    # Stop the temporary instance
    log "Stopping temporary MariaDB instance..."
    mysqladmin --socket=/tmp/mysql_temp.sock shutdown
    wait $MYSQL_PID
    
    log "MariaDB initial setup completed!"
else
    log "MariaDB database already initialized. Skipping setup."
fi

log "Starting MariaDB server..."
# Execute the main container command (CMD)
exec "$@"


#chmod +x inception/srcs/requirements/mariadb/tools/mariadb-setup.sh
