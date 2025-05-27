# Variables
IP_ADDRESS = 192.168.1.100
NETMASK = 24
GATEWAY = 192.168.1.1
DNS_SERVERS = 8.8.8.8,8.8.4.4
INTERFACE = eth0
NETPLAN_FILE = /etc/netplan/01-netcfg.yaml
# NETPLAN_FILE = /etc/netplan/01-network-manager-all.yaml 
CONFIG_TEMPLATE = netplan-config.yaml


# Default target
# all: install configure apply verify setdomain
all: network install_doker


network: configure_network verify setdomain

help:
	@echo "Użycie tego Makefile:"
	@echo '	first run "make install" to install docker'
	@echo "  make build   - Kompiluje projekt"
	@echo "  make clean   - Usuwa pliki tymczasowe"
	@echo "  make help    - Wyświetla tę pomoc"

.PHONY: help


install_docker:
	@sudo rm -f /etc/apt/sources.list.d/docker.list
	@echo "Installing Docker and Docker Compose..."
	@sudo apt update -y && sudo apt upgrade -y
	@sudo apt install -y ca-certificates curl gnupg lsb-release
	@sudo mkdir -p /etc/apt/keyrings
	@curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
	@if ! command -v lsb_release >/dev/null; then \
		echo "Error: lsb_release is not installed. Please install the lsb-release package."; \
		exit 1; \
	fi
	@if [ -z "$$(lsb_release -cs)" ]; then \
		echo "Error: Failed to determine the system release codename."; \
		exit 1; \
	fi
	@echo "System release codename: $$(lsb_release -cs)"
	@echo "Checking OS distribution..."
	@DISTRO=$$(lsb_release -is | tr '[:upper:]' '[:lower:]'); \
	CODENAME=$$(lsb_release -cs); \
	echo "Detected distribution: $$DISTRO"; \
	echo "Detected codename: $$CODENAME"; \
	if [ "$$DISTRO" = "ubuntu" ]; then \
		echo "Ubuntu detected, setting repository for Ubuntu..."; \
		echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $$CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; \
	elif [ "$$DISTRO" = "debian" ]; then \
		echo "Debian detected, setting repository for Debian..."; \
		echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $$CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; \
	else \
		echo "Error: Unsupported distribution: $$DISTRO"; \
		exit 1; \
	fi
	@echo "Repository file contents:"
	@cat /etc/apt/sources.list.d/docker.list
	@sudo apt update -y || { echo "Error: Failed to update package repositories!"; exit 1; }
	@sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
	@sudo systemctl start docker || { echo "Error: Failed to start Docker service!"; exit 1; }
	@sudo systemctl enable docker
	@sudo usermod -aG docker $$USER
	@echo "Verifying installation..."
	@docker --version || { echo "Error: Docker installation failed!"; exit 1; }
	@docker compose version || { echo "Error: Docker Compose installation failed!"; exit 1; }
	@echo "Installation completed successfully!"
	@echo "\033[31mNote: Log out and back in to apply Docker group changes, or run 'newgrp docker'.\033[0m"
	@echo "\033[31mTo immediately use Docker without logout, run: newgrp docker\033[0m"

# Create or update Netplan configuration
configure_network:
	@echo "Configuring static IP $(IP_ADDRESS)..."
	@sudo sh -c "cat $(CONFIG_TEMPLATE) > $(NETPLAN_FILE)"
	sudo apt update -y
	sudo apt install systemd-networkd -y
	sudo systemctl enable systemd-networkd
	sudo systemctl start systemd-networkd
	sudo systemctl disable NetworkManager
	sudo systemctl stop NetworkManager
	sudo rm -f /var/lib/dhcp/dhclient.leases
	sudo netplan apply
	sudo systemctl restart systemd-networkd

setdomain:
	@echo "2. Configure Networking"
	echo "192.168.1.100 login.42.fr" | sudo tee -a /etc/hosts


# Verify the IP configuration
verify:
	@echo "Verifying IP configuration..."
	@ip addr show $(INTERFACE) | grep -q $(IP_ADDRESS) && echo "IP $(IP_ADDRESS) is set" || echo "Failed to set IP $(IP_ADDRESS)"
	@ping -c 4 $(IP_ADDRESS) || echo "Ping to $(IP_ADDRESS) failed"

# Clean up (optional: restore DHCP or remove config)
clean:
	@echo "Restoring DHCP configuration..."
	@sudo sh -c "cat netplan-config_no_config.yaml > $(NETPLAN_FILE)"
	@sudo netplan apply
	sudo systemctl restart systemd-networkd


.PHONY: all configure verify clean