# Makefile
all: up

up:
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
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

.PHONY: all up down clean fclean re