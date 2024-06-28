# SPDX-FileCopyrightText: 2015 Angelo Veltens <angelo.veltens@online.de>
#
# SPDX-License-Identifier: MIT

FROM ubuntu:24.04

LABEL org.opencontainers.image.authors="Angelo Veltens <angelo.veltens@online.de>"

# install depenencies
RUN apt-get update && \
    apt-get install mysql-client cron bzip2 -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# copy scripts
COPY docker-entrypoint.sh /entrypoint.sh
COPY bin /bin/

# provide default configurations
ENV MYSQL_ENV_MYSQL_HOST mysql
ENV BACKUP_TIME 0 3 * * *

# create and prepare volume
RUN mkdir /backups
VOLUME /backups

# define entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cron", "-f"]
