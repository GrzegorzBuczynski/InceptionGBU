
# up:
# 	mkdir -p /home/${USER}/data/mariadb
# 	mkdir -p /home/${USER}/data/wordpress
# 	sudo chown -R 999:999 /home/${USER}/data/mariadb
# 	sudo chmod -R 755 /home/${USER}/data/mariadb
# 	sudo chown -R www-data:www-data /home/${USER}/data/wordpress
# 	sudo chmod -R 755 /home/${USER}/data/wordpress
# 	@if [ ! -f .env ]; then \
# 		if [ -f srcs/.env.example ]; then \
# 			echo "Copying srcs/.env.example to srcs/.env..."; \
# 			cp srcs/.env.example srcs/.env; \
# 		else \
# 			echo "Warning: srcs/.env.example not found!"; \
# 		fi; \
# 	else \
# 		echo ".env already exists"; \
# 	fi
# 	docker-compose -f srcs/docker-compose.yml up -d --build

# Makefile

# Default target
all: up

# Start containers
up:
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
	@if [ ! -f srcs/.env ]; then \
		echo "Creating .env file from example..."; \
		if [ -f srcs/.env.example ]; then \
			cp srcs/.env.example srcs/.env; \
		fi; \
		echo "\nDATA_PATH=/home/${USER}/data" >> srcs/.env; \
	else \
		echo ".env file already exists. Ensuring DATA_PATH is set..."; \
		grep -qF "DATA_PATH=" srcs/.env || echo "DATA_PATH=/home/${USER}/data" >> srcs/.env; \
	fi
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
