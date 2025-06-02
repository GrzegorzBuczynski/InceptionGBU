FROM debian:bullseye

# Zainstaluj MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Skopiuj konfigurację
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Skopiuj skrypt setup
COPY tools/mariadb-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb-setup.sh

# Przygotuj katalogi dla MariaDB
RUN mkdir -p /var/run/mysqld /var/lib/mysql /var/log/mysql \
    && chown -R mysql:mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql \
    && chown -R mysql:mysql /var/log/mysql

# Eksponuj port
EXPOSE 3306

# Uruchom jako root (kontener zarządza uprawnieniami wewnętrznie)
ENTRYPOINT ["/usr/local/bin/mariadb-setup.sh"]
CMD ["mysqld", "--user=mysql"]