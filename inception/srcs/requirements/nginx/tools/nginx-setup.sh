#!/bin/bash

if [ ! -f "/etc/ssl/certs/nginx.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx.key \
        -out /etc/ssl/certs/nginx.crt \
        -subj "/C=PL/ST=State/L=City/O=Organization/OU=OrgUnit/CN=${DOMAIN_NAME}"
fi

# Sprawdź czy nginx.conf jest prawidłowy
nginx -t

exec "$@"

#chmod +x inception/srcs/requirements/mariadb/tools/nginx-setup.sh
