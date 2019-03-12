set -ex

[ -e ".local-conf" ] && . ./.local-conf

PROJECT_PATH="${PROJECT_PATH-$(dirname "$(readlink -f "$0")")}"  # The full project path, e.g. /srv/tutor-web.beta
PROJECT_NAME="${PROJECT_NAME-$(basename ${PROJECT_PATH})}"  # The project directory name, e.g. tutor-web.beta
PROJECT_MODE="${PROJECT_MODE-development}"  # The project mode, development or production

SERVER_NAME="${SERVER_NAME-$(hostname --fqdn)}" # The server_name(s) NGINX responds to

systemctl | grep -q "${PROJECT_NAME}.service" && systemctl stop ${PROJECT_NAME}.service
cat <<EOF > /etc/systemd/system/${PROJECT_NAME}.service
[Unit]
Description=${PROJECT_NAME} daemon
After=network.target

[Service]
ExecStart=/usr/bin/nodejs ${PROJECT_PATH}/server/index.js ${APP_MCR_HOST}
WorkingDirectory=${PROJECT_PATH}/server
DynamicUser=yes
Restart=on-failure
RestartSec=5s
Type=simple
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF
systemctl enable ${PROJECT_NAME}.service
systemctl start ${PROJECT_NAME}.service
