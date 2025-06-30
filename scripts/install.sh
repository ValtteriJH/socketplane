#!/bin/sh

set -e -x

# Utility to check if a command exists
command_exists() {
    hash $@ 2>/dev/null
}

cleanup() {
    sudo socketplane agent stop
    sudo socketplane uninstall
    sudo rm -rf /opt/socketplane
    sudo rm -rf /usr/bin/socketplane
}

# Run as root only
if [ "$(id -u)" != "0" ]; then
    echo >&2 "Please run as root"
    exit 1
fi

if command_exists socketplane; then
    echo >&2 'Warning: "socketplane" command appears to already exist.'
    # echo >&2 'CRTL+C to exit out of this install.  Otherwise Socketplane will be reinstalled in 20 seconds'
echo "test"
    # sleep 20
    echo >&2 'CRTL+C to exit out of this install.  Otherwise Socketplane will be reinstalled in 5 seconds'
    sleep 5
    cleanup
fi

curl=''
if command_exists curl; then
    curl='curl -sSL -o'
elif command_exists wget; then
    curl='wget -q -O'
fi

sudo mkdir -p /opt/socketplane
sudo cp ./socketplane.sh /opt/socketplane/socketplane
sudo cp ./functions.sh /opt/socketplane/functions.sh
sudo mkdir -p /etc/socketplane
sudo cp ../socketplane.toml /etc/socketplane/socketplane.toml
sudo cp ../adapters.yml /etc/socketplane/adapters.yml
sudo chmod +x /opt/socketplane/socketplane
sudo ln -s /opt/socketplane/socketplane /usr/bin/socketplane
sleep 3

# Test if allow input from the terminal (0 = STDIN)

if [ -t 0 ]; then
  sudo socketplane install
else
  if [ -z $BOOTSTRAP ]; then
     export BOOTSTRAP=false
  fi
  sudo socketplane install unattended
fi
