#!/bin/bash

if [ ! -f "/etc/ssl/certs/nginx.crt" ]; then
    cat > /tmp/openssl.cnf <<EOF
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no

[ req_distinguished_name ]
C  = PL
ST = State
L  = City
O  = Organization
OU = OrgUnit
CN = ${DOMAIN_NAME}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN_NAME}
IP.1  = 192.168.1.100
EOF

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx.key \
        -out /etc/ssl/certs/nginx.crt \
        -config /tmp/openssl.cnf
fi

# Check if nginx.conf is correct
nginx -t

exec "$@"


#chmod +x inception/srcs/requirements/mariadb/tools/nginx-setup.sh
