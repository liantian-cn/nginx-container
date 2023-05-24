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
  tar -xzf /config.tar.gz -C /config
else
  echo "nginx.conf file exist, skipping extraction."
fi

TIMESTAMP=$(date +%Y-%m-%d-%H-%M)

if [ -f "/log/access.log" ]; then
  echo "/log/access.log file exist. Create a compressed copy..."
  gzip -c /log/access.log > /log/access_${TIMESTAMP}.log.gz
  rm /log/access.log

fi

touch /log/access.log

if [ -f "/log/error.log" ]; then
  echo "/log/error.log file exist. Create a compressed copy..."
  gzip -c /log/error.log > /log/error_${TIMESTAMP}.log.gz
  rm /log/access.log

fi

touch /log/access.log

if [ -f "/log/modsec_audit.log" ]; then
  echo "/log/modsec_audit.log file exist. Create a compressed copy..."
  gzip -c /log/modsec_audit.log > /log/modsec_audit_${TIMESTAMP}.log.gz
  rm /log/access.log

fi

touch /log/modsec_audit.log

chmod ugo+w /log/access.log
chmod ugo+w /log/access.log
chmod ugo+w /log/modsec_audit.log

exec "$@"
