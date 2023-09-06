.PHONY: build install run
build:
	GOOS=linux GOARCH=arm GOARM=6 go build -o build/prometheus-nmap-exporter github.com/clicube/prometheus-nmap-exporter

install: build
	ssh rpizw "sudo systemctl stop prometheus-nmap-exporter || exit 0"
	scp prometheus-nmap-exporter.service rpizw:/tmp/prometheus-nmap-exporter.service
	scp build/prometheus-nmap-exporter rpizw:/tmp/prometheus-nmap-exporter
	ssh rpizw "sudo mkdir -p /opt/prometheus-nmap-exporter && \
		sudo mv /tmp/prometheus-nmap-exporter /opt/prometheus-nmap-exporter/prometheus-nmap-exporter && \
		sudo chown root:root /opt/prometheus-nmap-exporter/prometheus-nmap-exporter && \
		sudo chmod 755 /opt/prometheus-nmap-exporter/prometheus-nmap-exporter && \
		sudo mv /tmp/prometheus-nmap-exporter.service /etc/systemd/system/prometheus-nmap-exporter.service && \
		sudo systemctl daemon-reload && \
		sudo systemctl enable prometheus-nmap-exporter && \
		sudo systemctl start prometheus-nmap-exporter"

run:
	go run github.com/clicube/prometheus-nmap-exporter
