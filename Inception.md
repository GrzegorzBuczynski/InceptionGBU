


To approach the Inception project as described, you need to set up a small infrastructure using Docker Compose, with specific services (NGINX, WordPress, MariaDB) running in containers on a virtual machine. The goal is to create a secure, well-configured web application infrastructure with WordPress, following strict guidelines. Below is a step-by-step guide to tackle this project effectively, ensuring compliance with the requirements.

Step-by-Step Approach to the Inception Project
1. Understand the Requirements
The project requires you to:

Use a Virtual Machine (VM) to host the infrastructure.
Create a srcs folder for configuration files and a Makefile at the root.
Use Docker Compose to orchestrate the services.
Build custom Docker images for:
NGINX (with TLSv1.2 or TLSv1.3, port 443 only).
WordPress + PHP-FPM (no NGINX in this container).
MariaDB (no NGINX).
Set up two volumes:
One for the WordPress database.
One for the WordPress website files.
Create a Docker network for container communication.
Ensure containers restart on crash.
Avoid forbidden practices (e.g., tail -f, sleep infinity, network: host, --link).
Use Alpine or Debian (penultimate stable version) as base images.
Store sensitive data in a .env file and use Docker secrets for credentials.
Configure a custom domain (e.g., login.42.fr) to point to your VM’s IP.
Set up a WordPress database with two users (one admin, no "admin" in username).
Store volumes in /home/login/data on the host VM.
2. Plan the Infrastructure
Based on the requirements, the infrastructure will look like this:

NGINX Container: Acts as the entry point, handling HTTPS requests (port 443) with TLSv1.2 or TLSv1.3. It proxies requests to the WordPress container.
WordPress + PHP-FPM Container: Runs the WordPress application, communicating with MariaDB for the database.
MariaDB Container: Stores the WordPress database.
Volumes:
WordPress database files (persistent storage for MariaDB).
WordPress website files (for themes, plugins, uploads).
Docker Network: Connects the containers for internal communication.
Domain: login.42.fr resolves to the VM’s IP, handled by NGINX.
3. Set Up the Virtual Machine
Create a VM:
Use a hypervisor like VirtualBox, VMware, or a cloud provider.
Install the penultimate stable version of Alpine Linux or Debian (e.g., Debian 12 if 13 is the latest).
Ensure Docker and Docker Compose are installed:
bash

Kopiuj
# For Debian
sudo apt update && sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
bash

Kopiuj
# For Alpine
apk add docker docker-compose
service docker start
rc-update add docker boot
Configure Networking:
Assign a static IP to the VM (e.g., 192.168.1.100).
Edit /etc/hosts on your local machine or VM to map login.42.fr to the VM’s IP:
bash

Kopiuj
echo "192.168.1.100 login.42.fr" | sudo tee -a /etc/hosts
Create Directory Structure:
bash

Kopiuj
mkdir -p inception/{srcs/requirements/{nginx/{conf,tools},wordpress/{conf,tools},mariadb/{conf,tools}},secrets}
touch inception/Makefile
touch inception/srcs/docker-compose.yml
touch inception/srcs/.env
This matches the expected structure in the subject.
4. Create Dockerfiles
Each service requires a custom Dockerfile in srcs/requirements/<service>.

NGINX Dockerfile (srcs/requirements/nginx/Dockerfile)
dockerfile

Kopiuj
FROM debian:bookworm-slim

# Install NGINX and OpenSSL
RUN apt-get update && apt-get install -y nginx openssl && apt-get clean

# Create directories for SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=${DOMAIN_NAME}"

# Copy NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Expose port 443
EXPOSE 443

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
Notes:
Use debian:bookworm-slim (penultimate stable Debian).
Generate a self-signed SSL certificate for login.42.fr.
Configure NGINX to use TLSv1.2 or TLSv1.3 (done in nginx.conf).
Run NGINX in the foreground to avoid daemon issues.
NGINX Configuration (srcs/requirements/nginx/conf/nginx.conf)
nginx

Kopiuj
events {}

http {
    server {
        listen 443 ssl;
        server_name login.42.fr;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location / {
            proxy_pass http://wordpress:9000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
WordPress Dockerfile (srcs/requirements/wordpress/Dockerfile)
dockerfile

Kopiuj
FROM debian:bookworm-slim

# Install PHP-FPM and dependencies
RUN apt-get update && apt-get install -y \
    php-fpm php-mysql curl && apt-get clean

# Install WordPress
RUN curl -o /tmp/wordpress.tar.gz -SL https://wordpress.org/latest.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /var/www/ \
    && rm /tmp/wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/wordpress

# Copy PHP-FPM configuration
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy WordPress configuration
COPY conf/wp-config.php /var/www/wordpress/wp-config.php

# Expose port for PHP-FPM
EXPOSE 9000

# Start PHP-FPM in foreground
CMD ["php-fpm7.4", "-F"]
Notes:
Install PHP-FPM and php-mysql for WordPress.
Download and extract the latest WordPress tarball.
Use a custom wp-config.php to set database credentials via environment variables.
WordPress Configuration (srcs/requirements/wordpress/conf/wp-config.php)
php

Kopiuj
<?php
define('DB_NAME', getenv('MYSQL_DATABASE'));
define('DB_USER', getenv('MYSQL_USER'));
define('DB_PASSWORD', getenv('MYSQL_PASSWORD'));
define('DB_HOST', 'mariadb');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('AUTH_KEY',         'put_your_unique_phrase_here');
define('SECURE_AUTH_KEY',  'put_your_unique_phrase_here');
define('LOGGED_IN_KEY',    'put_your_unique_phrase_here');
define('NONCE_KEY',        'put_your_unique_phrase_here');
define('AUTH_SALT',        'put_your_unique_phrase_here');
define('SECURE_AUTH_SALT', 'put_your_unique_phrase_here');
define('LOGGED_IN_SALT',   'put_your_unique_phrase_here');
define('NONCE_SALT',       'put_your_unique_phrase_here');

$table_prefix = 'wp_';
define('WP_DEBUG', false);

if (!defined('ABSPATH'))
    define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
Generate secure keys for wp-config.php using a WordPress key generator.
MariaDB Dockerfile (srcs/requirements/mariadb/Dockerfile)
dockerfile

Kopiuj
FROM debian:bookworm-slim

# Install MariaDB
RUN apt-get update && apt-get install -y mariadb-server && apt-get clean

# Copy MariaDB configuration
COPY conf/my.cnf /etc/mysql/my.cnf

# Copy initialization script
COPY tools/init.sql /docker-entrypoint-initdb.d/init.sql

# Expose MariaDB port
EXPOSE 3306

# Start MariaDB in foreground
CMD ["mysqld", "--bind-address=0.0.0.0"]
MariaDB Initialization Script (srcs/requirements/mariadb/tools/init.sql)
sql

Kopiuj
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wp_user'@'%' IDENTIFIED BY 'user_password';
CREATE USER IF NOT EXISTS 'wp_admin'@'%' IDENTIFIED BY 'admin_password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON wordpress.* TO 'wp_user'@'%';
FLUSH PRIVILEGES;
Notes:
Create two users: wp_user (regular) and wp_admin (admin, no "admin" in name).
Store passwords in Docker secrets or .env.
Bind MariaDB to 0.0.0.0 to allow connections from other containers.
5. Create Docker Compose File (srcs/docker-compose.yml)
yaml

Kopiuj
version: '3.8'

services:
  nginx:
    build: ./requirements/nginx
    container_name: nginx
    ports:
      - "443:443"
    volumes:
      - wp_files:/var/www/wordpress
    networks:
      - inception
    restart: always
    depends_on:
      - wordpress
    environment:
      - DOMAIN_NAME=${DOMAIN_NAME}

  wordpress:
    build: ./requirements/wordpress
    container_name: wordpress
    volumes:
      - wp_files:/var/www/wordpress
    networks:
      - inception
    restart: always
    depends_on:
      - mariadb
    environment:
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}

  mariadb:
    build: ./requirements/mariadb
    container_name: mariadb
    volumes:
      - wp_db:/var/lib/mysql
    networks:
      - inception
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}

volumes:
  wp_db:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/db
  wp_files:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/www

networks:
  inception:
    driver: bridge
Notes:
Define three services: nginx, wordpress, mariadb.
Map volumes to /home/login/data/{db,www}.
Use a bridge network named inception.
Set restart: always for crash recovery.
Use environment variables from .env.
6. Create .env File (srcs/.env)
env

Kopiuj
DOMAIN_NAME=login.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=user_password
MYSQL_ROOT_PASSWORD=root_password
Note: Ensure .env is listed in .gitignore to avoid exposing credentials.
7. Use Docker Secrets for Sensitive Data
Instead of hardcoding passwords in init.sql, use Docker secrets:

Create secret files in secrets/:
bash

Kopiuj
echo "user_password" > inception/secrets/db_user_password.txt
echo "admin_password" > inception/secrets/db_admin_password.txt
echo "root_password" > inception/secrets/db_root_password.txt
Update docker-compose.yml to include secrets:
yaml

Kopiuj
services:
  mariadb:
    ...
    secrets:
      - db_user_password
      - db_admin_password
      - db_root_password

secrets:
  db_user_password:
    file: ./secrets/db_user_password.txt
  db_admin_password:
    file: ./secrets/db_admin_password.txt
  db_root_password:
    file: ./secrets/db_root_password.txt
Update init.sql to read secrets:
sql

Kopiuj
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wp_user'@'%' IDENTIFIED BY '`cat /run/secrets/db_user_password`';
CREATE USER IF NOT EXISTS 'wp_admin'@'%' IDENTIFIED BY '`cat /run/secrets/db_admin_password`';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON wordpress.* TO 'wp_user'@'%';
FLUSH PRIVILEGES;
8. Create Makefile
makefile

Kopiuj
all: up

up:
	@mkdir -p /home/login/data/db /home/login/data/www
	@docker-compose -f srcs/docker-compose.yml up --build -d

down:
	@docker-compose -f srcs/docker-compose.yml down

clean:
	@docker-compose -f srcs/docker-compose.yml down -v
	@docker system prune -a --volumes

re: clean all

.PHONY: all up down clean re
Notes:
Creates volume directories.
Builds and starts containers in detached mode.
Includes clean and re (rebuild) targets.
9. Test the Setup
Run make to build and start the containers.
Access https://login.42.fr in a browser to verify WordPress is running.
Log in to WordPress using the admin credentials (wp_admin).
Check container logs for errors:
bash

Kopiuj
docker logs nginx
docker logs wordpress
docker logs mariadb
10. Best Practices and Tips
Read Documentation:
Docker: Dockerfile best practices, Docker Compose, and networking.
NGINX: Configuring SSL/TLS.
WordPress: wp-config.php setup.
MariaDB: Secure initialization and user management.
Avoid Common Pitfalls:
Don’t use tail -f, sleep infinity, or similar hacks.
Ensure containers run in the foreground (e.g., nginx -g "daemon off;", php-fpm -F).
Use environment variables and secrets for sensitive data.
Security:
Use strong, unique passwords in secrets.
Restrict MariaDB to the Docker network (bind to 0.0.0.0 only within the network).
Ensure TLS is properly configured (test with openssl s_client -connect login.42.fr:443).
Testing:
Verify volumes are mounted in /home/login/data.
Test WordPress setup by creating a post as the admin user.
Simulate container crashes to ensure restart: always works.
11. Troubleshooting
NGINX Errors: Check SSL certificate paths and nginx.conf syntax (nginx -t).
WordPress Errors: Verify wp-config.php credentials and MariaDB connectivity.
MariaDB Errors: Ensure init.sql runs correctly and users are created.
Networking: Use docker network inspect inception to verify container connectivity.
12. Final Checklist
<input type="checkbox" disabled> VM is set up with Alpine/Debian.
<input type="checkbox" disabled> Dockerfiles for NGINX, WordPress, MariaDB are custom-built.
<input type="checkbox" disabled> Docker Compose defines all services, volumes, and networks.
<input type="checkbox" disabled> NGINX uses TLSv1.2 or TLSv1.3 and listens on port 443.
<input type="checkbox" disabled> WordPress has PHP-FPM and connects to MariaDB.
<input type="checkbox" disabled> MariaDB has two users (one admin, no "admin" in name).
<input type="checkbox" disabled> Volumes are mounted in /home/login/data.
<input type="checkbox" disabled> .env and secrets are used for credentials.
<input type="checkbox" disabled> login.42.fr resolves to the VM’s IP.
<input type="checkbox" disabled> Containers restart on crash.
<input type="checkbox" disabled> Makefile builds and runs the infrastructure.
This approach ensures a clean, secure, and compliant setup for the Inception project. If you need specific code snippets, configuration details, or help with a particular step, let me know!