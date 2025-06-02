FROM debian:bullseye

RUN mkdir -p /run/php && chown www-data:www-data /run/php
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    curl \
    wget \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Skopiuj konfigurację PHP-FPM
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Skopiuj i ustaw uprawnienia dla skryptu setup
COPY tools/wordpress-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wordpress-setup.sh

# Utwórz katalog roboczy
WORKDIR /var/www/html

# Eksponuj port PHP-FPM
EXPOSE 9000

# Uruchom skrypt setup i PHP-FPM
ENTRYPOINT ["/usr/local/bin/wordpress-setup.sh"]
CMD ["php-fpm7.4", "-F"]