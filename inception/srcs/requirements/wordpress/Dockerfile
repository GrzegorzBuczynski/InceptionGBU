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

RUN wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz && \
   tar -xzf /tmp/wordpress.tar.gz -C /tmp/ && \
   rm /tmp/wordpress.tar.gz && \
   chown -R www-data:www-data /tmp/wordpress  

# Copy PHP-FPM configuration
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy and set permissions for setup script
COPY tools/wordpress-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wordpress-setup.sh

# Create working directory
WORKDIR /var/www/html

# Expose PHP-FPM port
EXPOSE 9000

# Run setup script and PHP-FPM
ENTRYPOINT ["/usr/local/bin/wordpress-setup.sh"]
CMD ["php-fpm7.4", "-F"]