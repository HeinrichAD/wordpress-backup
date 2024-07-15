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

  db_name="$(get_env MYSQL_ENV_MYSQL_DATABASE)"

  # create and register cron job
  echo "MYSQL_ENV_MYSQL_DATABASE=\"$db_name\"" > /backup-cron
  [ -n "$CLEANUP_OLDER_THAN" ] && echo "CLEANUP_OLDER_THAN=\"$CLEANUP_OLDER_THAN\"" >> /backup-cron
  [ -n "$BACKUP_TIMESTAMP" ] && echo "BACKUP_TIMESTAMP=\"$BACKUP_TIMESTAMP\"" >> /backup-cron
  [ -n "$BACKUP_FILES_UID" ] && echo "BACKUP_FILES_UID=\"$BACKUP_FILES_UID\"" >> /backup-cron
  [ -n "$BACKUP_FILES_GID" ] && echo "BACKUP_FILES_GID=\"$BACKUP_FILES_GID\"" >> /backup-cron
  echo "$BACKUP_TIME backup > /backups/last-backup.log 2>&1" >> /backup-cron
  crontab /backup-cron

  # create log file with correct permissions
  credentials="${BACKUP_FILES_UID:-$(id -u)}:${BACKUP_FILES_GID:-$(id -g)}"
  touch /backups/last-backup.log
  chown "$credentials" /backups/last-backup.log
fi

log_info "Current crontab:"
crontab -l


# configure MySQLDump settings
# ------------------------------------------

db_host="$(get_env MYSQL_ENV_MYSQL_HOST)"
db_user="$(get_env MYSQL_ENV_MYSQL_USER)"
db_password="$(get_env MYSQL_ENV_MYSQL_PASSWORD)"

log_info "Creating MySQLDump configuration file"
touch /etc/mysql/conf.d/mysqlpassword.cnf
chmod 600 /etc/mysql/conf.d/mysqlpassword.cnf
cat <<-EOF > /etc/mysql/conf.d/mysqlpassword.cnf
; backup settings
[mysqldump]
host="$db_host"
user="$db_user"
password="$db_password"

; restore settings
[mysql]
host="$db_host"
user="$db_user"
password="$db_password"
EOF


exec "$@"
