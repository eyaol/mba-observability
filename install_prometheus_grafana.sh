#!/bin/bash

#
# CONFIGURAÇÃO PROMETHEUS
#

# instalação de ferramentas e utilitários
sudo dnf -y install zlib-devel pam-devel openssl-devel libtool bison flex autoconf gcc make git net-tools lsof net-tools

# criação de usuário prometheus para executar prometheus
sudo useradd -m -s /bin/false prometheus

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
metadata_expire=300"

# escrever o conteúdo no arquivo prometheus-rpm_release.repo
sudo echo "$repo_content" | sudo tee "$repo_file" > /dev/null

# instalar o prometheus
sudo dnf install prometheus -y

# prometheus.service
service_prometheus_service="/etc/systemd/system/prometheus.service"
service_prometheus_content="[Unit]
Description=Prometheus Time Series Collection and Processing Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target"

# escrever o conteúdo no arquivo prometheus.service
sudo echo "$service_prometheus_content" | sudo tee "$service_prometheus_service" > /dev/null

# criação do arquivo cpu.yml 
file_path_cpu="/etc/prometheus/cpu.yml"
file_content_cpu="groups:
- name: cpu_alerts
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 5
    for: 30s
    labels:
      severity: warning
    annotations:
      summary: High CPU usage on instance {{\$labels.instance}}
      description: CPU usage is above 5% on instance {{\$labels.instance}}"

sudo echo "$file_content_cpu" > "$file_path_cpu"

# criação do arquivo memoria.yml
file_path_memoria="/etc/prometheus/memoria.yml"
file_content_memoria="groups:
- name: memory_alerts
  rules:
  - alert: HighMemoryUsage
    expr: (node_memory_Active_bytes / node_memory_MemTotal_bytes) * 100 > 20
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: High memory usage on instance {{\$labels.instance}}
      description: Memory usage is above 20% on instance {{\$labels.instance}}"

sudo echo "$file_content_memoria" > "$file_path_memoria"

# criação do arquivo disco.yml
file_path_disco="/etc/prometheus/disco.yml"
file_content_disco="groups:
- name: disk_alerts
  rules:
  - alert: HighDiskUsage
    expr: 100 - (node_filesystem_avail_bytes * 100 / node_filesystem_size_bytes) > 10
    for: 30s
    labels:
      severity: warning
    annotations:
      summary: High disk usage on instance {{\$labels.instance}}
      description: Disk usage is above 10% on instance {{\$labels.instance}}"

sudo echo "$file_content_disco" > "$file_path_disco"

# criação do arquivo porta.yml
file_path_porta="/etc/prometheus/porta.yml"
file_content_porta="groups:
- name: port80_alerts
  rules:
  - alert: Port80DownAlert
    expr: up == 0
    for: 1m
    labels:
      severity: critical
      port: \"80\"
    annotations:
      summary: Porta 80 fora do ar
      description: A porta 80 do host {{\$labels.instance}} está fora do ar"

sudo echo "$file_content_porta" > "$file_path_porta"

# reload daemon para reexaminar os arquivos de configuração do systemd
sudo systemctl daemon-reload

# inicializar o prometheus
sudo systemctl start prometheus

# prometheus.yml
file_path_prometheus="/etc/prometheus/prometheus.yml"
file_content_prometheus="global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
rule_files:
  - 'cpu.yml'
  - 'memoria.yml'
  - 'disco.yml'
  - 'porta.yml'
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "node"
    static_configs:
      - targets: ["172.31.16.20:9100"]"

# truncate file
sudo echo -n > "$file_path_prometheus"

# escrever novo conteúdo no arquivo prometheus.yml
sudo echo "$file_content_prometheus" > "$file_path_prometheus"

# reinicializar a aplicação do prometheus
sudo systemctl restart prometheus

#
# CONFIGURAÇÃO GRAFANA
#

# grafana.repo
repo_grafana="/etc/yum.repos.d/grafana.repo"
repo_grafana_content="[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt"

sudo echo "$repo_grafana_content" > "$repo_grafana"

# atualizar policies
sudo update-crypto-policies --set DEFAULT:SHA1

# reiniciar o prometheus
sudo systemctl restart prometheus

# instalar o grafana
sudo dnf install grafana -y

# reload daemon para reexaminar os arquivos de configuração do systemd
sudo systemctl daemon-reload

# configurar serviços para iniciar automaticamente
sudo systemctl enable --now grafana-server
sudo systemctl enable prometheus