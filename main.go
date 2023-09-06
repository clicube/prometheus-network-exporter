package main

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/Ullaakut/nmap/v3"
)

func main() {
	http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		fmt.Println("request received: /metrics")
		ctx, cancel := context.WithTimeout(r.Context(), 1*time.Minute)
		defer cancel()

		scanner, err := nmap.NewScanner(
			ctx,
			nmap.WithTargets("192.168.1.0/24"),
			nmap.WithPingScan(),
			nmap.WithMaxParallelism(4),
		)
		if err != nil {
			fmt.Printf("unable to create nmap scanner: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
		}

		result, warnings, err := scanner.Run()
		if len(*warnings) > 0 {
			fmt.Printf("run finished with warnings: %s\n", *warnings) // Warnings are non-critical errors from nmap.
		}
		if err != nil {
			fmt.Printf("unable to run nmap scan: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
		}

		// Use the results to print an example output
		for _, host := range result.Hosts {
			var ipv4 string
			var mac string
			for _, addr := range host.Addresses {
				if addr.AddrType == "ipv4" {
					ipv4 = addr.Addr
				} else if addr.AddrType == "mac" {
					mac = addr.Addr
				}
			}
			if host.Status.Reason == "localhost-response" {
				mac, _ = getMacAddr(ipv4)
			}
			fmt.Printf("IPv4: %s, MAC: %s\n", ipv4, mac)
			fmt.Fprintf(w, "host_up{ip=\"%s\",mac=\"%s\"} 1\n", ipv4, mac)
		}

		fmt.Printf("Nmap done: %d hosts up scanned in %.2f seconds\n", len(result.Hosts), result.Stats.Finished.Elapsed)
	})

	fmt.Println("server starting on port 8001")
	http.ListenAndServe(":8001", nil)
}

func getMacAddr(ip string) (string, error) {
	ifas, err := net.Interfaces()
	if err != nil {
		return "", err
	}
	for _, ifa := range ifas {
		addrs, err := ifa.Addrs()
		if err != nil {
			return "", err
		}
		for _, a := range addrs {
			if strings.Index(a.String(), ip) == 0 {
				return strings.ToUpper(ifa.HardwareAddr.String()), nil
			}
		}
	}
	return "", nil
}
