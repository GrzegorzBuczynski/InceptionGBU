FROM debian:bullseye

# Install MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy config
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy setup script
COPY tools/mariadb-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb-setup.sh

# Prepare directories for MariaDB
RUN mkdir -p /var/run/mysqld /var/lib/mysql /var/log/mysql \
    && chown -R mysql:mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql \
    && chown -R mysql:mysql /var/log/mysql

# Expose port
EXPOSE 3306

# Run as  root (container controls internaly)
ENTRYPOINT ["/usr/local/bin/mariadb-setup.sh"]
CMD ["mysqld", "--user=mysql"]