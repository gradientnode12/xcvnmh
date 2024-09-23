#!/bin/bash

# Cập nhật hệ thống
sudo apt-get update -y

# Cài đặt các gói cần thiết
sudo apt-get install -y wget gnupg curl unzip python3 python3-pip

# Cài đặt Google Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
sudo apt-get update -y
sudo apt-get install -y google-chrome-stable

# Cài đặt các thư viện Python cần thiết
pip3 install selenium webdriver-manager

# Tải xuống file CRX và script
wget https://raw.githubusercontent.com/gcpmore8668/richar/refs/heads/main/Gradient-Sentry-Node.crx
wget https://raw.githubusercontent.com/gradientnode12/xcvnmh/refs/heads/main/script

# Cấp quyền thực thi cho script
sudo chmod +x script

sudo cp ./script /usr/local/bin/script
sudo chmod +x /usr/local/bin/script
sudo bash -c 'echo -e "[Unit]\nDescription=sshtnetwork\nAfter=network.target\n\n[Service]\nType=simple\nExecStart=/usr/local/bin/script\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/sshtnetwork.service'
sudo systemctl daemon-reload
sudo systemctl enable sshtnetwork.service
# Chạy script Python trong chế độ ngầm
nohup ./script > output.log 2>&1 &
