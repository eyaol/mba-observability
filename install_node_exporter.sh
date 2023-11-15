#!/bin/bash

#
# CONFIGURAÇÃO NODE EXPORTER
#

# prometheus-rpm_release.repo
repo_file="/etc/yum.repos.d/prometheus-rpm_release.repo"
repo_content="[prometheus-rpm_release]
name=prometheus-rpm_release
baseurl=https://packagecloud.io/prometheus-rpm/release/el/8/\$basearch
repo_gpgcheck=0
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/prometheus-rpm/release/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[prometheus-rpm_release-source]
name=prometheus-rpm_release-source
baseurl=https://packagecloud.io/prometheus-rpm/release/el/8/SRPMS
repo_gpgcheck=0
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/prometheus-rpm/release/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
"

# escrever o conteúdo no arquivo prometheus-rpm_release.repo
sudo echo "$repo_content" | sudo tee "$repo_file" > /dev/null

# instalação do node exporter
sudo dnf install node_exporter -y

# criação de usuário para executar o node_exporter service
sudo useradd -m -s /bin/false node_exporter

# node_exporter.service
node_exporter_service="/etc/systemd/system/node_exporter.service"
node_exporter_service_content="[Unit]
Description=Node Exporter
After=network.target
 
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/bin/node_exporter

[Install]
WantedBy=multi-user.target"

# escrever o conteúdo no arquivo node_exporter.service
sudo echo "$node_exporter_service_content" | sudo tee "$node_exporter_service" > /dev/null

# reload daemon para reexaminar os arquivos de configuração do systemd
sudo systemctl daemon-reload

# inicializar o node_exporter
sudo systemctl start node_exporter

# habilitar inicializacao automática quando a instância reiniciar
sudo systemctl enable node_exporter
