# Use the official OpenResty image as the base
FROM openresty/openresty:1.21.4.1-0-jammy

# Define the environment variable with a default value
ENV BACKEND_SERVER=http://127.0.0.1:8080
ENV ATTRIBUTE_USERNAME=preferred_username
ENV ATTRIBUTE_EMAIL=email

RUN apt update && apt install openssl

# Rebuild and reinstall lua-resty-rsa with the existing OpenSSL
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-rsa
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-jwt
RUN /usr/local/openresty/luajit/bin/luarocks install lua-cjson
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-openssl

# Copy your custom NGINX configuration file (assuming it's named nginx.conf)
COPY nginx.conf /etc/nginx/nginx.conf.template

# Copy the Lua script into the container
COPY jwt_decoder.lua /etc/nginx/jwt_decoder.lua

# Expose port 80
EXPOSE 80

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
