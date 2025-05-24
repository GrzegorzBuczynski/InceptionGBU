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
all: configure apply verify setdomain

help:
	@echo "Użycie tego Makefile:"
	@echo '	first run "make install" to install docker'
	@echo "  make build   - Kompiluje projekt"
	@echo "  make clean   - Usuwa pliki tymczasowe"
	@echo "  make help    - Wyświetla tę pomoc"

.PHONY: help

install:
	@echo "Installing docker and docker-compose!"
	sudo apt update && sudo apt install -y docker.io docker-compose
	sudo systemctl start docker
	sudo systemctl enable docker
	@echo "Instalation ended!"

setdomain:
	@echo "2. Configure Networking"
	echo "192.168.1.100 login.42.fr" | sudo tee -a /etc/hosts


# Create or update Netplan configuration
configure:
	@echo "Configuring static IP $(IP_ADDRESS)..."
	@sudo sh -c "cat $(CONFIG_TEMPLATE) > $(NETPLAN_FILE)"
	sudo apt update
	sudo apt install systemd-networkd
	sudo systemctl enable systemd-networkd
	sudo systemctl start systemd-networkd
	sudo systemctl disable NetworkManager
	sudo systemctl stop NetworkManager
	sudo rm -f /var/lib/dhcp/dhclient.leases
	sudo netplan apply
	sudo systemctl restart systemd-networkd


# Apply the Netplan configuration
apply:
	@echo "Applying network configuration..."
	@sudo netplan apply

# Verify the IP configuration
verify:
	@echo "Verifying IP configuration..."
	@ip addr show $(INTERFACE) | grep -q $(IP_ADDRESS) && echo "IP $(IP_ADDRESS) is set" || echo "Failed to set IP $(IP_ADDRESS)"
	@ping -c 4 $(IP_ADDRESS) || echo "Ping to $(IP_ADDRESS) failed"

# Clean up (optional: restore DHCP or remove config)
clean:
	@echo "Restoring DHCP configuration..."
	@sudo netplan apply

.PHONY: all configure apply verify clean