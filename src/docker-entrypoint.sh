#!/bin/bash

# SPDX-FileCopyrightText: 2015 Angelo Veltens <angelo.veltens@online.de>
#
# SPDX-License-Identifier: MIT

# import utils
# shellcheck disable=SC2034
LOG_SOURCE_NAME="Entrypoint"
source "$(dirname "${BASH_SOURCE[0]}")/bin/utils.sh"


# check required environment variables
# ------------------------------------------

check_env MYSQL_ENV_MYSQL_HOST
check_env MYSQL_ENV_MYSQL_DATABASE
check_env MYSQL_ENV_MYSQL_USER
check_env MYSQL_ENV_MYSQL_PASSWORD


# register backup cron job
# ------------------------------------------

if ! [ -f backup-cron ] && [ -n "$BACKUP_TIME" ]; then
  log_info "Creating cron entry to start backup at: $BACKUP_TIME"
  echo "$BACKUP_TIME backup > /backups/last-backup.log 2>&1" >> /backup-cron
  crontab /backup-cron
fi

log_info "Current crontab:"
crontab -l


# configure MySQLDump settings
# ------------------------------------------

db_password="$(get_env MYSQL_ENV_MYSQL_PASSWORD)"

log_info "Creating MySQLDump configuration file"
touch /etc/mysql/conf.d/mysqlpassword.cnf
chmod 600 /etc/mysql/conf.d/mysqlpassword.cnf
cat <<-EOF > /etc/mysql/conf.d/mysqlpassword.cnf
; backup settings
[mysqldump]
host="$MYSQL_ENV_MYSQL_HOST"
user="$MYSQL_ENV_MYSQL_USER"
password="$db_password"

; restore settings
[mysql]
host="$MYSQL_ENV_MYSQL_HOST"
user="$MYSQL_ENV_MYSQL_USER"
password="$db_password"
EOF


exec "$@"
