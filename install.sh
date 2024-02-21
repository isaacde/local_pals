#!/bin/bash

# == Configuration Section ==
IFS=','
declare -A config_targets=(
    ["Palworld"]="TCP_PORT_LIST=8211,27015,27016,25575 ; UDP_PORT_LIST=8211,27015,27016,25575"
    ["Palworld2"]="TCP_PORT_LIST=27015,27016,25575 ; UDP_PORT_LIST=8211,27015,27016,25575"
    # ... Add more targets here ...
)
# IFS=','

CONFIG_TARGET_LIST=("${!config_targets[@]}")

# Process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      CONFIG_TARGET="$2"
      # == Config Target Validation ==
      # check if a valid config was passed and then set variables for that config
      if [[ ! -z "$CONFIG" && ! -v config_targets[$CONFIG_TARGET] ]]; then
        echo "Error: Invalid --config-target provided."
        echo "  Should be one of: ${CONFIG_TARGET_LIST[*]}"
        exit 1
      else
        eval "${config_targets[$CONFIG_TARGET]}"
        CONFIG_NAME="$CONFIG_TARGET"
      fi
      shift 2 ;;
    -n|--name)
      CONFIG_NAME="$2"
      shift 2 ;;
    -t|--tcp-port-list)
      TCP_PORT_LIST="$2"
      shift 2 ;;
    -u|--udp-port-list)
      UDP_PORT_LIST="$2"
      shift 2 ;;
    -s|--server-ip)
      SERVER_IP="$2"
      shift 2 ;;
    -h|--help)
      echo "Usage: $0 -c CONFIG_TARGET -s SERVER_IP"
      echo "Options:"
      echo "  -c, --config-target       Select a predefined TCP/UDP config target. Valid configs: ${CONFIG_TARGET_LIST[*]}"
      echo "  -n, --name                Set the name of the configuration. Filled by default value if --config-target is set."
      echo "  -u, --tcp-port-list       Sets the TCP ports to forward. Enter as comma separated list with no spaces. Filled by default value if --config-target is set."
      echo "  -u, --udp-port-list       Sets the UDP ports to forward. Enter as comma separated list with no spaces. Filled by default value if --config-target is set."
      echo "  -s, --server-ip           Required: Sets the local server IP to forward ports to"
      echo "  -h, --help                Displays this help message"
      exit 0 ;;
    *)
      echo "Unknown option: $1"
      exit 1 ;;
  esac
done

# check if ports are made with numericals like they should be
IFS=',' read -ra tcp_ports <<< "$TCP_PORT_LIST" 
for port in "${tcp_ports[@]}"; do
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Invalid TCP port: $port. Ports must contain only digits."
    exit 1 
  fi
done

IFS=',' read -ra udp_ports <<< "$UDP_PORT_LIST" 
for port in "${udp_ports[@]}"; do
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Invalid UDP port: $port. Ports must contain only digits."
    exit 1 
  fi
done

# Check any ports were provided
if [[ -z "$TCP_PORT_LIST" && -z "$UDP_PORT_LIST" ]]; then
  echo "Error: At least one TCP or UDP port must be set to forward. Please provide either:"
  echo "  -c, --config-target CONFIG_TARGET_NAME (one of: ${CONFIG_TARGET_LIST[*]})"
  echo "  -t, --tcp-port-list TCP_PORT_LIST"
  echo "  -u, --udp-port-list UDP_PORT_LIST"
  echo "  TCP/UDP_PORT_LIST must be provided as a list of port numbers separated by commas."
  exit 1
fi
# Check any ports were provided
if [[ -z "$TCP_PORT_LIST" && -z "$UDP_PORT_LIST" ]]; then
  echo "Error: At least one TCP or UDP port must be set to forward. Please provide either:"
  echo "  -t, --tcp-port-list TCP_PORT_LIST"
  echo "  -u, --udp-port-list UDP_PORT_LIST"
  echo "  *_PORT_LIST must be provided as a list of port numbers separated by commas."
  exit 1
fi

# Check if SERVER_IP is set
if [[ -z "$SERVER_IP" ]]; then
  echo "Error: server IP (-s|--server-ip) is required."
  exit 1
fi

# == Print what we want to do ==
echo "Configuration name: $CONFIG_NAME"
echo "Target TCP Ports: $TCP_PORT_LIST"
echo "Target UDP Ports: $UDP_PORT_LIST"
echo "Server IP: $SERVER_IP"

# == Create the desktop file from the template ==
export CONFIG_NAME
export TCP_PORT_LIST
export UDP_PORT_LIST
export SERVER_IP
export ICON_ENABLE="palworld.png"
export ICON_DISABLE="palworld.png"

DESKTOP_TEMPLATE="applications/local_pals.desktop.template"
DESKTOP_FILE="applications/local_pals.$CONFIG_NAME.desktop"

envsubst < "$DESKTOP_TEMPLATE" > "$DESKTOP_FILE"

# Target locations (adhere to XDG standards)
DESKTOP_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.local/share/icons"
SCRIPTS_DIR="$HOME/.local/bin"

# Create the target directories if needed
mkdir -p $DESKTOP_DIR $ICONS_DIR $SCRIPTS_DIR

# Copy files to their respective locations 
cp applications/*.desktop $DESKTOP_DIR
cp icons/*.png $ICONS_DIR
cp bin/*.sh $SCRIPTS_DIR

echo "Installation complete!"


exit 0