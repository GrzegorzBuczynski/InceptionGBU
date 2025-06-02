# srcs/requirements/nginx/Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/nginx-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/nginx-setup.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/nginx-setup.sh"]
CMD ["nginx", "-g", "daemon off;"]