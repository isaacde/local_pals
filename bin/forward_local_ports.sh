#!/bin/bash

# Process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--server-ip)
      SERVER_IP="$2"  # Set SERVER_IP based on the argument value
      shift 2 ;;  # Shift arguments to process the next one
    -t|--tcp-port-list)
      TCP_PORT_LIST="$2"
      shift 2 ;;
    -u|--udp-port-list)
      UDP_PORT_LIST="$2"
      shift 2 ;;
    -r|--remove-forwarding)
      REMOVE_FORWARDING="1"
      shift 1 ;;
    -h|--help)
      echo "Usage: $0 [-s|--server-ip SERVER_IP] [other options]"
      echo "Options:"
      echo "  -s, --server-ip           Sets the local server IP to forward ports to"
      echo "  -u, --tcp-port-list       Sets the TCP ports to forward. Enter as comma separated list with no spaces."
      echo "  -u, --udp-port-list       Sets the UDP ports to forward. Enter as comma separated list with no spaces."
      echo "  -r, --remove-forwarding   Removes the forwarding for the given ports to any server."
      echo "  -h, --help                Displays this help message"
      exit 0 ;;
    *)
      echo "Unknown option: $1"
      exit 1 ;;
  esac
done

# Check any ports were provided
if [[ -z "$TCP_PORT_LIST" && -z "$UDP_PORT_LIST" ]]; then
  echo "Error: At least one TCP or UDP port must be set to forward. Please provide either:"
  echo "  -t, --tcp-port-list TCP_PORT_LIST"
  echo "  -u, --udp-port-list UDP_PORT_LIST"
  echo "  *_PORT_LIST must be provided as a list of port numbers separated by commas."
  exit 1
fi

# Convert comma-separated list to array
OLD_IFS=$IFS
IFS=',' read -ra tcp_ports <<< "$TCP_PORT_LIST" 
IFS=',' read -ra udp_ports <<< "$UDP_PORT_LIST" 
IFS=$OLD_IFS

# Validate if ports contain only digits. Remove existing routing.
for port in "${tcp_ports[@]}"; do
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Invalid TCP port: $port. Ports must contain only digits."
    exit 1 
  fi

  iptables -t nat -D PREROUTING -p tcp --dport "$port" -j DNAT > /dev/null 2>&1

  if [[ $? -eq 0 ]]; then
    echo "iptables rule(s) for TCP port $port successfully removed."
  fi
done

for port in "${udp_ports[@]}"; do
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Invalid UDP port: $port. Ports must contain only digits."
    exit 1 
  fi

  iptables -t nat -D PREROUTING -p udp --dport "$port" -j DNAT > /dev/null 2>&1

  if [[ $? -eq 0 ]]; then
    echo "iptables rule(s) for UDP port $port successfully removed."
  fi
done

if [[ -z "$REMOVE_FORWARDING" ]]; then
  echo "Removed forwarding. Exiting!."
  exit 0
fi

# Check if SERVER_IP is set
if [[ -z "$SERVER_IP" ]]; then
  echo "Error: server IP (-s|--server-ip) is required."
  exit 1
fi

for port in "${tcp_ports[@]}"; do
  iptables -t nat -A OUTPUT -d 127.0.0.1 -p tcp --dport "$port" -j DNAT --to-destination "$SERVER_IP"

  if [[ $? -eq 0 ]]; then
    echo "iptables rule to forward TCP traffic to 127.0.0.1:$port to $SERVER_IP successfully created."
  else
    echo "iptables rule for TCP port $port could not be created."
  fi
done

for port in "${udp_ports[@]}"; do
  iptables -t nat -A OUTPUT -d 127.0.0.1 -p udp --dport "$port" -j DNAT --to-destination "$SERVER_IP"

  if [[ $? -eq 0 ]]; then
    echo "iptables rule to forward UDP traffic to 127.0.0.1:$port to $SERVER_IP successfully created."
  else
    echo "iptables rule for UDP port $port could not be created."
  fi
done

echo "Done!"
