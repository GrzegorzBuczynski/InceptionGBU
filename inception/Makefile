# Makefile

# Force make to use bash for all shell commands, ensuring compatibility.
SHELL := /bin/bash

# variable
ENV_FILE = srcs/.env
ENV_VARS = DOMAIN_NAME WP_ADMIN_USER WP_ADMIN_EMAIL WP_USER WP_USER_EMAIL DATA_PATH
SECRETS = mysql_database mysql_password mysql_root_password mysql_user wp_admin_password wp_user_password

# Default target
all: up

# Start containers with all checks
up: init-all
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
	sudo rm -rf /home/${USER}/data

# Rebuild everything from scratch
re: fclean all

# More aggressive cleaning
purge: down
	docker system prune -af --volumes
	sudo rm -rf /home/${USER}/data
	docker network prune -f
	-docker rmi srcs_mariadb srcs_wordpress srcs_nginx 2>/dev/null || true

# Show logs
logs:
	docker-compose -f srcs/docker-compose.yml --env-file $(ENV_FILE) logs

logs-db:
	docker-compose -f srcs/docker-compose.yml logs -f mariadb

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


# Declare phony targets to avoid conflicts with file names
.PHONY: all up down clean fclean re purge logs logs-db logs-wp diagnose_maria images status conect_nginx_container volumes docker_encryption list_network inspect inspect2 init-env init-secrets init-all