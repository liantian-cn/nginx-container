#!/bin/bash

# Check if /config directory exists
if [ ! -d "/config" ]; then
  # If not, create the /config directory
  echo "Creating /config directory..."
  mkdir -p /config
else
  echo "/config directory already exists."
fi

if [ ! -f "/config/nginx.conf" ]; then
  echo "missing nginx.conf. Extracting origin_config.tar.gz to /config..."
  tar -xzf /origin_config.tar.gz -C /config
else
  echo "nginx.conf file exist, skipping extraction."
fi

# 检查 /log/access.log 文件是否存在，如果不存在则创建该文件
if [ ! -f "/log/access.log" ]; then
  echo "/log/access.log file does not exist. Creating it..."
  touch /log/access.log
fi

if [ ! -f "/log/error.log" ]; then
  echo "/log/error.log file does not exist. Creating it..."
  touch /log/error.log
fi

chmod ugo+w /log/access.log
chmod ugo+w /log/error.log

exec "$@"
