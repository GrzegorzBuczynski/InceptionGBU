# Makefile

# Force make to use bash for all shell commands, ensuring compatibility.
SHELL := /bin/bash

# Default target
all: up

# -----------------------------------------------------------------------------
# -- INITIALIZATION TARGETS (Called automatically by 'up')
# -----------------------------------------------------------------------------

# Interactive secrets initialization
init-secrets:
	@echo "-------------------------------------------------------------------"; \
	echo "The 'secrets' directory is missing or empty."; \
	echo "This will copy example credentials from 'secrets.example' to 'secrets'."; \
	if [ ! -d "secrets.example" ]; then \
		echo "Error: 'secrets.example' directory not found. Cannot proceed."; \
		exit 1; \
	fi; \
	echo "Replace example credentials with your own"; \
	echo "To confirm, please type the phrase below and press Enter:"; \
	echo "==> copy example credentials"; \
	read -p "Your confirmation: " user_input; \
	if [[ "$$user_input" == "copy example credentials" ]]; then \
		echo "Confirmation received. Copying example credentials..."; \
		mkdir -p secrets; \
		cp -v secrets.example/* secrets/; \
		echo "Credentials copied successfully."; \
	else \
		echo "Confirmation failed. Aborting."; \
		exit 1; \
	fi; \
	echo "-------------------------------------------------------------------"

# Environment file (.env) initialization
init-env:
	@if [ ! -f srcs/.env ]; then \
		echo "Creating .env file from example..."; \
		if [ -f srcs/.env.example ]; then \
			cp srcs/.env.example srcs/.env; \
		fi; \
		echo -e "\n# Path to data volumes, automatically added by Makefile" >> srcs/.env; \
		echo "DATA_PATH=/home/${USER}/data" >> srcs/.env; \
	else \
		echo ".env file already exists. Ensuring DATA_PATH is set..."; \
		grep -qF "DATA_PATH=" srcs/.env || echo "DATA_PATH=/home/${USER}/data" >> srcs/.env; \
	fi

# -----------------------------------------------------------------------------
# -- MAIN WORKFLOW TARGETS
# -----------------------------------------------------------------------------

# Start containers with all checks
up:
	@# Step 1: Initialize secrets if missing
	@if [ ! -d "secrets" ] || [ -z "$$(ls -A secrets 2>/dev/null)" ]; then \
		$(MAKE) init-secrets; \
	fi
	@# Step 2: Initialize .env file
	$(MAKE) init-env
	@# Step 3: Create data directories on the host
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
	@# Step 4: Run Docker Compose
	echo "Starting Docker containers..."
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build

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

# Declare phony targets to avoid conflicts with file names
.PHONY: all up down clean fclean re purge logs images status polacz_nginx volumes docker_encryption list_network inspect inspect2
