.PHONY: build install run
build:
	GOOS=linux GOARCH=arm GOARM=6 go build -o build/prometheus-network-exporter github.com/clicube/prometheus-network-exporter

install: build
	ssh rpizw "sudo systemctl stop prometheus-network-exporter || exit 0"
	scp prometheus-network-exporter.service rpizw:/tmp/prometheus-network-exporter.service
	scp build/prometheus-network-exporter rpizw:/tmp/prometheus-network-exporter
	ssh rpizw "sudo mkdir -p /opt/prometheus-network-exporter && \
		sudo mv /tmp/prometheus-network-exporter /opt/prometheus-network-exporter/prometheus-network-exporter && \
		sudo chown root:root /opt/prometheus-network-exporter/prometheus-network-exporter && \
		sudo chmod 755 /opt/prometheus-network-exporter/prometheus-network-exporter && \
		sudo mv /tmp/prometheus-network-exporter.service /etc/systemd/system/prometheus-network-exporter.service && \
		sudo systemctl daemon-reload && \
		sudo systemctl enable prometheus-network-exporter && \
		sudo systemctl start prometheus-network-exporter"

run:
	go run github.com/clicube/prometheus-network-exporter
