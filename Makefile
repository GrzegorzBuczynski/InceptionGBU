

.PHONY: create-backup-config setup-static-ip restore-ip-config setup-domain remove-domain

# Network configuration variables
INTERFACE ?= enp0s3
STATIC_IP ?= 192.168.1.100
NETMASK ?= 255.255.255.0
GATEWAY ?= 192.168.1.1
DNS1 ?= 8.8.8.8
DNS2 ?= 8.8.4.4
NETWORK_FILE = /etc/network/interfaces
BACKUP_FILE = /etc/network/interfaces.backup

# Domain configuration variables
DOMAIN_IP ?= 192.168.1.100
DOMAIN_NAME ?= login.42.fr
HOSTS_FILE = /etc/hosts

install_docker2: 
	@sudo apt update && sudo apt install -y docker.io docker-compose
	@sudo systemctl start docker
	@sudo systemctl enable docker

install_docker: docker docker_compose

docker_compose:
	@echo "Fixing docker.list file..."
	@sudo rm -f /etc/apt/sources.list.d/docker.list
	@echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	@sudo apt update
	@sudo apt install -y curl
	@sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-$$(uname -s)-$$(uname -m)" -o /usr/local/bin/docker-compose
	@sudo chmod +x /usr/local/bin/docker-compose
	@docker-compose --version

install_git:
	@sudo apt update
	@sudo apt install git

docker:
	@sudo apt update && sudo apt upgrade -y
	@sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
	curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	@sudo apt update
	@sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
	@sudo systemctl start docker
	@sudo systemctl enable docker
	@sudo docker --version
	@sudo usermod -aG docker $$USER

# Setup local domain mapping
setup-domain:
	@echo "Setting up local domain: $(DOMAIN_NAME) -> $(DOMAIN_IP)"
	@if ! grep -q "$(DOMAIN_NAME)" $(HOSTS_FILE); then \
		echo "$(DOMAIN_IP) $(DOMAIN_NAME)" | sudo tee -a $(HOSTS_FILE) > /dev/null; \
		echo "Domain $(DOMAIN_NAME) added to hosts file"; \
	else \
		echo "Domain $(DOMAIN_NAME) already exists in hosts file"; \
	fi

# Remove local domain mapping
remove-domain:
	@echo "Removing local domain: $(DOMAIN_NAME)"
	sudo sed -i "/$(DOMAIN_NAME)/d" $(HOSTS_FILE)
	@echo "Domain $(DOMAIN_NAME) removed from hosts file"

# Create backup of current network configuration
create-backup-config:
	@echo "Creating backup of network configuration..."
	sudo cp $(NETWORK_FILE) $(BACKUP_FILE)
	@echo "Backup created: $(BACKUP_FILE)"

setup-static-ip:
	@echo "Setting up static IP configuration..."
	sed 's/enp0s3/$(INTERFACE)/g' interfaces.static > interfaces.tmp
	@echo "Generated config:"
	@cat interfaces.tmp
	sudo cp interfaces.tmp $(NETWORK_FILE)
	rm interfaces.tmp
	-sudo systemctl stop dhcpcd 2>/dev/null || true
	-sudo systemctl disable dhcpcd 2>/dev/null || true
	@echo "Restarting networking service..."
	-sudo systemctl restart networking || echo "Networking restart failed, trying alternative method"
	-sudo ifdown $(INTERFACE) && sudo ifup $(INTERFACE) || echo "Interface restart failed"
	@echo "Static IP configuration completed"


restore-dhcp:
	@echo "Restoring DHCP configuration..."
	sed 's/enp0s3/$(INTERFACE)/g' interfaces.dhcp > interfaces.tmp
	@echo "Generated DHCP config:"
	@cat interfaces.tmp
	sudo cp interfaces.tmp $(NETWORK_FILE)
	rm interfaces.tmp
	-sudo systemctl enable dhcpcd 2>/dev/null || true
	-sudo systemctl start dhcpcd 2>/dev/null || true
	@echo "Restarting networking service..."
	-sudo systemctl restart networking || echo "Networking restart failed, trying alternative method"
	-sudo ifdown $(INTERFACE) && sudo ifup $(INTERFACE) || echo "Interface restart failed"
	@echo "DHCP configuration restored"

# Restore network configuration from backup
restore-ip-config:
	@if [ -f $(BACKUP_FILE) ]; then \
		echo "Restoring network configuration from backup..."; \
		sudo cp $(BACKUP_FILE) $(NETWORK_FILE); \
		sudo systemctl restart networking; \
		echo "Configuration restored from backup"; \
	else \
		echo "Error: Backup file $(BACKUP_FILE) not found"; \
		exit 1; \
	fi

create_dir_structure:
	mkdir -p inception/srcs/requirements/nginx/conf
	mkdir -p inception/srcs/requirements/nginx/tools
	mkdir -p inception/srcs/requirements/wordpress/conf
	mkdir -p inception/srcs/requirements/wordpress/tools
	mkdir -p inception/srcs/requirements/mariadb/conf
	mkdir -p inception/srcs/requirements/mariadb/tools
	mkdir -p inception/secrets
	touch inception/Makefile
	touch inception/srcs/docker-compose.yml
	touch inception/srcs/.env


