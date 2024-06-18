set -ex

[ -e ".local-conf" ] && . ./.local-conf

APP_PORT="${APP_PORT-8888}"

PROJECT_PATH="${PROJECT_PATH-$(dirname "$(readlink -f "$0")")}"  # The full project path
PROJECT_NAME="${PROJECT_NAME-$(basename ${PROJECT_PATH})}"  # The project directory name

WWW_SERVER_NAME="${WWW_SERVER_NAME-$(hostname --fqdn)}" # The server_name(s) NGINX responds to

systemctl | grep -q "${PROJECT_NAME}.service" && systemctl stop ${PROJECT_NAME}.service
cat <<EOF > /etc/systemd/system/${PROJECT_NAME}.service
[Unit]
Description=${PROJECT_NAME} daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/nodejs ${PROJECT_PATH}/server/index.js ${APP_MCR_HOST} ${APP_PORT}
WorkingDirectory=${PROJECT_PATH}/server
DynamicUser=yes
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable ${PROJECT_NAME}.service
systemctl start ${PROJECT_NAME}.service

echo -n "" > /etc/nginx/sites-available/${PROJECT_NAME}

if [ -n "${WWW_CERT_PATH}" -a -e "${WWW_CERT_PATH}/certs/${WWW_SERVER_NAME}/fullchain.pem" ]; then
    # Generate full-blown SSL config
    cat <<EOF >> /etc/nginx/sites-available/${PROJECT_NAME}
server {
    listen      80;
    server_name ${WWW_SERVER_NAME};
    location /.well-known/acme-challenge/ {
        alias "${WWW_CERT_PATH}/acme-challenge/";
    }
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
server {
    listen [::]:443 ssl;
    listen      443 ssl;
    server_name ${WWW_SERVER_NAME};
    ssl_certificate      ${WWW_CERT_PATH}/certs/${WWW_SERVER_NAME}/fullchain.pem;
    ssl_certificate_key  ${WWW_CERT_PATH}/certs/${WWW_SERVER_NAME}/privkey.pem;
    ssl_trusted_certificate ${WWW_CERT_PATH}/certs/${WWW_SERVER_NAME}/fullchain.pem;
    ssl_dhparam ${WWW_CERT_PATH}/dhparam.pem;
    # https://mozilla.github.io/server-side-tls/ssl-config-generator/
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    # intermediate configuration. tweak to your needs.
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_prefer_server_ciphers on;
EOF
elif [ -n "${WWW_CERT_PATH}" ]; then
    # HTTP only, but add acme-challenge section for bootstrapping
    cat <<EOF >> /etc/nginx/sites-available/${PROJECT_NAME}
server {
    listen      80;
    server_name ${WWW_SERVER_NAME};
    location /.well-known/acme-challenge/ {
        alias "${WWW_CERT_PATH}/acme-challenge/";
    }
EOF
else
    # HTTP only
    cat <<EOF >> /etc/nginx/sites-available/${PROJECT_NAME}
server {
    listen      80;
    server_name ${WWW_SERVER_NAME};
EOF
fi

cat <<EOF >> /etc/nginx/sites-available/${PROJECT_NAME}
    charset     utf-8;
    gzip        on;
    location / {
        proxy_pass  http://localhost:${APP_PORT}/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade         \$http_upgrade;
        proxy_set_header Connection      "upgrade";
        proxy_set_header Host            \$host;
        proxy_set_header X-Forwarded-For \$remote_addr;
    }
}
EOF
ln -fs /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/${PROJECT_NAME}
nginx -t
systemctl reload nginx.service
