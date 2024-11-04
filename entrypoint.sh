#!/bin/sh
# Substitute environment variables in the nginx configuration
envsubst '$BACKEND_SERVER' < /etc/nginx/nginx.conf.template > /usr/local/openresty/nginx/conf/nginx.conf
echo "Backend server: $BACKEND_SERVER"
echo "Starting OpenResty (NGINX) with the following configuration:"
cat /usr/local/openresty/nginx/conf/nginx.conf
# Start OpenResty (NGINX)
exec /usr/local/openresty/bin/openresty -g 'daemon off;'
