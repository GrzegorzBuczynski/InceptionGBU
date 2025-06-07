# Makefile

# Force make to use bash for all shell commands, ensuring compatibility.
SHELL := /bin/bash

# Default target
all: up

# Start containers with all checks
up: check-config
	@echo Create data directories on the host
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
	@# Step 4: Run Docker Compose
	echo "Starting Docker containers..."
# docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build

# Stop containers
down:
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env down

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
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env logs

logs-db:
	docker-compose -f srcs/docker-compose.yml logs -f mariadb

logs-wp:
	docker-compose -f srcs/docker-compose.yml logs -f wordpress

diagnose_maria:
	docker-compose -f srcs/docker-compose.yml logs mariadb

# List docker images
images:
	docker images

# Show container status
status:
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env ps

# Access nginx container shell
polacz_nginx:
	docker exec -it nginx bash

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




# Check both .env and secrets
check-config: check-env check-secrets
	@echo "🎉 All configuration ready!"

 
ENV_FILE = srcs/.env

# Checks for .env file and validates its content
check-env:
	@echo "🔎 Checking environment configuration..."
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "❌ Error: Configuration file '$(ENV_FILE)' not found."; \
		echo "➡️  Run 'make init' to create it."; \
		exit 1; \
	fi
	@missing_vars=0; \
	for var in DOMAIN_NAME WP_ADMIN_USER WP_ADMIN_EMAIL WP_USER WP_USER_EMAIL DATA_PATH; do \
		if ! grep -q "^$$var=" $(ENV_FILE); then \
			echo "❌ Missing variable '$$var' in $(ENV_FILE)"; \
			missing_vars=$$((missing_vars + 1)); \
		fi; \
	done; \
	if [ $$missing_vars -gt 0 ]; then \
		echo "\n🔧 Error: Found $$missing_vars missing variable(s). Please fix '$(ENV_FILE)'."; \
		exit 1; \
	fi
	@echo "✅ Environment configuration is OK."

# Check secrets folder
check-secrets:
	@echo "Check if secrets/* exist"
	@if [ ! -d "secrets" ]; then \
		echo "❌ Missing secrets/ - run 'make init-secrets'"; \
		exit 1; \
	fi; \
	missing=0; \
	for file in mysql_database mysql_password mysql_root_password mysql_user wp_admin_password wp_user_password; do \
		if [ ! -f "secrets/$$file" ]; then \
			echo "❌ Missing secrets/$$file"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	if [ $$missing -gt 0 ]; then \
		echo "🔧 Fix secrets/ or run 'make init-secrets'"; \
		exit 1; \
	fi; \
	echo "✅ secrets OK"

# Create .env file
init-env:
	@mkdir -p srcs
	@echo "#.env" > $(ENV_FILE);
	@echo DOMAIN_NAME=login.42.fr >> $(ENV_FILE);
	@echo WP_ADMIN_USER=site_admin >> $(ENV_FILE);
	@echo WP_ADMIN_EMAIL=admin@jkowalski.42.fr >> $(ENV_FILE);
	@echo WP_USER=regular_user >> $(ENV_FILE);
	@echo WP_USER_EMAIL=user@jkowalski.42.fr >> $(ENV_FILE);
	@echo DATA_PATH=/home/user/data >> $(ENV_FILE);
	@echo "✅ Created srcs/.env"

# Create secrets files
init-secrets:
	@mkdir -p secrets
	@echo "my_wordpress_db" > secrets/mysql_database
	@echo "user_password123" > secrets/mysql_password
	@echo "root_password123" > secrets/mysql_root_password
	@echo "wordpress_user" > secrets/mysql_user
	@echo "admin_password123" > secrets/wp_admin_password
	@echo "user_password123" > secrets/wp_user_password
	@echo "✅ Created secrets/ files"

# Create both
init-all: init-env init-secrets


# Declare phony targets to avoid conflicts with file names
.PHONY: all up down clean fclean re purge logs images status polacz_nginx volumes docker_encryption list_network inspect inspect2
