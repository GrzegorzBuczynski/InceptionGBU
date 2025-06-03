# Makefile
all: up

up:
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
	sudo chown -R 999:999 /home/${USER}/data/mariadb
	sudo chown -R www-data:www-data /home/${USER}/data/wordpress
	@if [ ! -f .env ]; then \
		if [ -f .env.example ]; then \
			echo "Copying .env.example to .env..."; \
			cp .env.example .env; \
		else \
			echo "Warning: .env.example not found!"; \
		fi; \
	else \
		echo ".env already exists"; \
	fi
	docker-compose -f srcs/docker-compose.yml up -d --build

down:
	docker-compose -f srcs/docker-compose.yml down

clean: down
	docker system prune -af
	docker volume prune -f

fclean: clean
	sudo rm -rf /home/${USER}/data

re: fclean all

logs:
	docker-compose log

images:
	docker images

status:
	docker-compose -f srcs/docker-compose.yml ps

polacz_nginx:
	docker exec -it nginx bash

volumes:
	docker volume ls

.PHONY: all up down clean fclean re


# Lista wszystkich sieci
list_network:
	docker network ls

# Szczegóły konkretnej sieci
inspect:
	docker network inspect inception_network

# Zobacz które kontenery są podłączone
inspect2:
	docker network inspect inception_network | grep -A 10 "Containers"
