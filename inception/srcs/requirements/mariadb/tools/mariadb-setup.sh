#!/bin/bash
# srcs/requirements/mariadb/tools/mariadb-setup.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] MariaDB: $1"
}

log "Starting MariaDB setup..."

# Define a marker file to check if setup has been completed
MARKER_FILE="/var/lib/mysql/.mariadb_initialized"

# Check if the marker file does NOT exist
if [ ! -f "$MARKER_FILE" ]; then
    log "Initialization marker not found. Starting first-time setup..."

    # Load secrets into variables
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
    MYSQL_DATABASE=$(cat /run/secrets/mysql_database)
    MYSQL_USER=$(cat /run/secrets/mysql_user)
    MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)

    # Ensure the data directory is owned by mysql user
    chown -R mysql:mysql /var/lib/mysql
    
    # Initialize the database system if the directory is truly empty
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        log "Data directory appears empty, running mysql_install_db..."
        mysql_install_db --user=mysql --datadir=/var/lib/mysql --rpm
    fi

    log "Starting temporary MariaDB instance for setup..."
    mysqld_safe --user=mysql --skip-networking --socket=/tmp/mysql.sock &
    MYSQL_PID=$!

    # Wait for it to be ready
    until mysqladmin ping --socket=/tmp/mysql.sock --silent; do
        log "Waiting for temporary MariaDB instance to be ready..."
        sleep 1
    done
    log "Temporary MariaDB instance is ready."

    log "Executing SQL setup block..."
    # Execute SQL setup. Piping the commands is more robust than a heredoc in some shells.
    # This block now also creates the user and database.
    mysql --socket=/tmp/mysql.sock -u root << EOF
SET SESSION sql_log_bin=0;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    log "SQL setup block executed."

    # Final check: Verify that the WordPress user can actually connect
    log "Verifying WordPress user connection..."
    if ! mysqladmin --socket=/tmp/mysql.sock -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" ping --silent; then
        log "FATAL ERROR: WordPress user cannot connect after setup. Aborting."
        exit 1
    fi
    log "WordPress user connection verified successfully."

    log "Stopping temporary MariaDB instance..."
    # Use the new root password to shut down the server
    if ! mysqladmin --socket=/tmp/mysql.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown; then
        log "Could not shut down temporary server. Killing process."
        kill -9 $MYSQL_PID
    fi
    
    # This line will only be reached if all previous commands were successful
    touch "$MARKER_FILE"
    log "MariaDB initial setup completed! Initialization marker created."

else
    log "Initialization marker found. Skipping setup."
fi

log "Starting main MariaDB server..."
exec "$@"



#chmod +x inception/srcs/requirements/mariadb/tools/mariadb-setup.sh
