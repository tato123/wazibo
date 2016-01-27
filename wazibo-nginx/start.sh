#!/bin/bash
# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and

# Env says we're using SSL

# Env says we're using SSL
if [ -n "${ENABLE_SSL+1}" ] && [ "${ENABLE_SSL,,}" = "true" ]; then
  echo "Enabling SSL..."
  cp /usr/src/proxy_ssl.conf /etc/nginx/conf.d/proxy.conf
  cp /usr/src/default_ssl.conf /etc/nginx/conf.d/default.conf
else
  # No SSL
  cp /usr/src/proxy_nossl.conf /etc/nginx/conf.d/proxy.conf
  cp /usr/src/default_nossl.conf /etc/nginx/conf.d/default.conf
fi

# If an htpasswd file is provided, download and configure nginx
if [ -n "${ENABLE_BASIC_AUTH+1}" ] && [ "${ENABLE_BASIC_AUTH,,}" = "true" ]; then
  echo "Enabling basic auth..."
   sed -i "s/#auth_basic/auth_basic/g;" /etc/nginx/conf.d/proxy.conf
fi

if [ -n "${WEB_SERVER_NAME+1}" ]; then
  # get value of the env variable in WEB_SERVICE_HOST_ENV_NAME as host, if that's not set,
  # WEB_SERVICE_HOST_ENV_NAME has the host value
  WEB_SERVER_NAME=${!WEB_SERVER_NAME:=$WEB_SERVER_NAME}
fi

if [ -n "${API_SERVER_NAME+1}" ]; then
  # get value of the env variable in WEB_SERVICE_HOST_ENV_NAME as host, if that's not set,
  # WEB_SERVICE_HOST_ENV_NAME has the host value
  API_SERVER_NAME=${!API_SERVER_NAME:=$API_SERVER_NAME}
fi

if [ -n "${CERT_SERVER_NAME+1}" ]; then
  # get value of the env variable in WEB_SERVICE_HOST_ENV_NAME as host, if that's not set,
  # WEB_SERVICE_HOST_ENV_NAME has the host value
  CERT_SERVER_NAME=${!CERT_SERVER_NAME:=$CERT_SERVER_NAME}
fi

if [ -n "${WEB_SERVICE_HOST_ENV_NAME+1}" ]; then
  # get value of the env variable in WEB_SERVICE_HOST_ENV_NAME as host, if that's not set,
  # WEB_SERVICE_HOST_ENV_NAME has the host value
  WEB_TARGET_SERVICE=${!WEB_SERVICE_HOST_ENV_NAME:=$WEB_SERVICE_HOST_ENV_NAME}
fi
if [ -n "${WEB_SERVICE_PORT_ENV_NAME+1}" ]; then
  # get value of the env variable in WEB_SERVICE_PORT_ENV_NAME as port, if that's not set,
  # WEB_SERVICE_PORT_ENV_NAME has the port value
  WEB_TARGET_SERVICE="$WEB_TARGET_SERVICE:${!WEB_SERVICE_PORT_ENV_NAME:=$WEB_SERVICE_PORT_ENV_NAME}"
fi

if [ -n "${API_SERVICE_HOST_ENV_NAME+1}" ]; then
  # get value of the env variable in API_SERVICE_HOST_ENV_NAME as host, if that's not set,
  # API_SERVICE_HOST_ENV_NAME has the host value
  API_TARGET_SERVICE=${!API_SERVICE_HOST_ENV_NAME:=$API_SERVICE_HOST_ENV_NAME}
fi
if [ -n "${API_SERVICE_PORT_ENV_NAME+1}" ]; then
  # get value of the env variable in API_SERVICE_PORT_ENV_NAME as port, if that's not set,
  # API_SERVICE_PORT_ENV_NAME has the port value
  API_TARGET_SERVICE="$API_TARGET_SERVICE:${!API_SERVICE_PORT_ENV_NAME:=$API_SERVICE_PORT_ENV_NAME}"
fi

# If the CERT_SERVICE_HOST_ENV_NAME and CERT_SERVICE_PORT_ENV_NAME vars
# are provided, they point to the env vars set by Kubernetes that contain the
# actual target address and port of the encryption service. Override the
# default with them.
if [ -n "${CERT_SERVICE_HOST_ENV_NAME+1}" ]; then
  CERT_SERVICE=${!CERT_SERVICE_HOST_ENV_NAME}
fi
if [ -n "${CERT_SERVICE_PORT_ENV_NAME+1}" ]; then
  CERT_SERVICE="$CERT_SERVICE:${!CERT_SERVICE_PORT_ENV_NAME}"
fi

if [ -n "${CERT_SERVICE+1}" ]; then
    # Tell nginx the address and port of the certification service.
    sed -i "s/{{CERT_SERVICE}}/${CERT_SERVICE}/g;" /etc/nginx/conf.d/proxy.conf
    sed -i "s/#letsencrypt# //g;" /etc/nginx/conf.d/proxy.conf
fi

# Tell nginx the name of the service
sed -i "s/{{SERVER_NAME}}/${SERVER_NAME}/g;" /etc/nginx/conf.d/proxy.conf
# Tell nginx the address and port of the service to proxy to
sed -i "s|{{WEB_TARGET_SERVICE}}|${WEB_TARGET_SERVICE}|" /etc/nginx/conf.d/proxy.conf
# Tell nginx the address and port of the service to proxy to
sed -i "s|{{API_TARGET_SERVICE}}|${API_TARGET_SERVICE}|" /etc/nginx/conf.d/proxy.conf
# Replace our server names
sed -i "s|{{API_SERVER_NAME}}|${API_SERVER_NAME}|" /etc/nginx/conf.d/proxy.conf
# Replace our server names
sed -i "s|{{WEB_SERVER_NAME}}|${WEB_SERVER_NAME}|" /etc/nginx/conf.d/proxy.conf
# Replace our server names
sed -i "s|{{CERT_SERVER_NAME}}|${CERT_SERVER_NAME}|" /etc/nginx/conf.d/proxy.conf

echo "Nginx Configuration"
cat /etc/nginx/conf.d/proxy.conf

echo "Starting nginx..."
nginx -g 'daemon off;'
