# Makefile

# Force make to use bash for all shell commands, ensuring compatibility.
SHELL := /bin/bash

# variable
ENV_FILE = srcs/.env
ENV_VARS = DOMAIN_NAME WP_ADMIN WP_ADMIN_EMAIL WP_USER WP_USER_EMAIL SITE_TITLE
SECRETS = mysql_database mysql_user mysql_password mysql_root_password wp_admin_password wp_user_password

# Default target
all: up

# Start containers with all checks
up: init-all nginx_conf iptables
	@echo Create data directories on the host
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
	@echo "Starting Docker containers..."
	docker-compose -f srcs/docker-compose.yml --env-file $(ENV_FILE) up -d --build

# Stop containers
down:
	docker-compose -f srcs/docker-compose.yml --env-file $(ENV_FILE) down

# Clean stopped containers and networks
clean: down
	docker system prune -af
	docker volume prune -f

# Clean everything including data
fclean: clean
	-docker volume rm srcs_mariadb_data srcs_wordpress_data 2>/dev/null || true
	sudo rm -rf /home/${USER}/data

# Rebuild everything from scratch
re: fclean all

# More aggressive cleaning
purge: down
	docker system prune -af --volumes
	-docker volume rm srcs_mariadb_data srcs_wordpress_data 2>/dev/null || true
	sudo rm -rf /home/${USER}/data
	docker network prune -f
	-docker rmi srcs_mariadb srcs_wordpress srcs_nginx 2>/dev/null || true

# Show logs
logs:
	docker-compose -f srcs/docker-compose.yml --env-file $(ENV_FILE) logs

logs-db:
	docker-compose -f srcs/docker-compose.yml logs -f mariadb

logs-ng:
	docker-compose -f srcs/docker-compose.yml logs nginx

# -f stays for with follow mode
logs-wp:
	docker-compose -f srcs/docker-compose.yml logs -f wordpress

# without follow mode
diagnose_maria:
	docker-compose -f srcs/docker-compose.yml logs mariadb

# List docker images
images:
	docker images

# Show container status
status:
	docker-compose -f srcs/docker-compose.yml --env-file $(ENV_FILE) ps

# Access nginx container shell
conect_nginx_container:
	docker exec -it nginx bash

conect_mariadb_container:
	docker exec -it mariadb bash

conect_wordpress_container:
	docker exec -it wordpress bash

update_wordpress_sh:
	docker cp srcs/requirements/wordpress/tools/wordpress-setup.sh wordpress:/usr/local/bin/

update_nginx.conf:
	docker cp srcs/requirements/nginx/conf/nginx.conf nginx:/etc/nginx/

# List docker volumes
volumes:
	docker volume ls

# Check Nginx TLS/SSL protocols
docker_encryption:
	docker exec nginx nginx -T | grep ssl_protocols

# List all networks
list_network:
	docker network ls

# Inspect the main network
inspect:
	docker network inspect inception_network

# Inspect network to see connected containers
inspect2:
	docker network inspect inception_network | grep -A 10 "Containers"
 
# Create .env file
init-env:
	@echo "🔍 Checking if .env variables exist"
	@mkdir -p srcs
	@touch $(ENV_FILE)
	@for var in $(ENV_VARS); do \
	if [ -z "$$(grep "^$$var=" $(ENV_FILE) | cut -d'=' -f2)" ]; then \
		input=""; \
		while [ -z "$$input" ]; do \
			read -p "Type $$var and press enter: " input; \
		done; \
		if grep -q "^$$var=" $(ENV_FILE); then \
			sed -i "s/^$$var=.*/$$var=$$input/" $(ENV_FILE); \
		else \
			echo "$$var=$$input" >> $(ENV_FILE); \
		fi; \
	fi; \
	done
	@echo "✅ .env file ok"

# Create secrets files
init-secrets:
	@echo "🔍 Checking if secrets/ exist"
	@mkdir -p secrets
	@for item in $(SECRETS); do \
		if [ -z "$$(cat secrets/$$item 2>/dev/null)" ]; then \
			while [ -z "$$input" ]; do \
				read -p "Type $$item and press enter: " input; \
			done && echo $$input > secrets/$$item; \
			unset input; \
		fi; \
	done
	@echo "✅ secrets/ OK"

# Create both
init-all: init-env init-secrets
	@echo "🎉 All configuration ready!"

nginx_conf:
	@echo "creating nginx.conf"
	@DOMAIN_NAME=$$(grep ^DOMAIN_NAME= srcs/.env | cut -d '=' -f2) ; \
	SAFE_DOMAIN_NAME=$$(printf '%s\n' "$$DOMAIN_NAME" | sed 's/[\/&]/\\&/g') ; \
	sed "s/login\.42\.fr/$$SAFE_DOMAIN_NAME/" srcs/requirements/nginx/conf/nginx.conf.template > srcs/requirements/nginx/conf/nginx.conf
# @echo "creating tools/nginx-setup.sh"
# @DOMAIN_NAME=$$(grep ^DOMAIN_NAME= srcs/.env | cut -d '=' -f2) ; \
# SAFE_DOMAIN_NAME=$$(printf '%s\n' "$$DOMAIN_NAME" | sed 's/[\/&]/\\&/g') ; \
# sed "s/DOMAIN_NAME/$$SAFE_DOMAIN_NAME/" srcs/requirements/nginx/tools/nginx-setup.template.sh > srcs/requirements/nginx/tools/nginx-setup.sh

iptables:
	sudo iptables -P INPUT ACCEPT
	sudo iptables -P FORWARD ACCEPT
	sudo iptables -P OUTPUT ACCEPT
	sudo iptables -A INPUT -i lo -j ACCEPT
	sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A INPUT -i docker0 -p tcp --dport 443 -j ACCEPT
	sudo iptables -A INPUT -i docker0 -j DROP
# sudo iptables -F
# sudo iptables -X


iptables_save:
	sudo apt install iptables-persistent
	sudo netfilter-persistent save

iptables_check:
	sudo iptables -L -n -v


# Declare phony targets to avoid conflicts with file names
.PHONY: all up down clean fclean re purge logs logs-db logs-wp diagnose_maria images status conect_nginx_container volumes docker_encryption list_network inspect inspect2 init-env init-secrets init-all