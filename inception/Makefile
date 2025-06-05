# Makefile
all: up

up:
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
	sudo chown -R 999:999 /home/${USER}/data/mariadb
	sudo chmod -R 755 /home/${USER}/data/mariadb
	sudo chown -R www-data:www-data /home/${USER}/data/wordpress
	sudo chmod -R 755 /home/${USER}/data/wordpress
	@if [ ! -f .env ]; then \
		if [ -f srcs/.env.example ]; then \
			echo "Copying srcs/.env.example to srcs/.env..."; \
			cp srcs/.env.example srcs/.env; \
		else \
			echo "Warning: srcs/.env.example not found!"; \
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

# Dodaj te zasady:
re: fclean up

down:
	docker-compose -f srcs/docker-compose.yml down

# Jeszcze bardziej agresywne czyszczenie (opcjonalne)
purge: down
	docker system prune -af --volumes
	sudo rm -rf /home/${USER}/data
	docker network prune -f
	# Usuń konkretne obrazy jeśli istnieją
	-docker rmi srcs_mariadb srcs_wordpress srcs_nginx 2>/dev/null || true

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

# Sprawdź czy nginx używa odpowiednich wersji TLS
docker_encryption:
	docker exec nginx nginx -T | grep ssl_protocols
	docker exec nginx nginx -T | grep ssl_protocols

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
