<!--
SPDX-FileCopyrightText: 2015 Angelo Veltens <angelo.veltens@online.de>

SPDX-License-Identifier: MIT
-->

# wordpress-backup

wordpress-backup is a simple [Docker](https://www.docker.com/) container that helps you backup and restore your WordPress blog.

[![Dockerhub badge](http://dockeri.co/image/aveltens/wordpress-backup)](https://hub.docker.com/r/aveltens/wordpress-backup)

## Quick start

Precondition: Given you have a WordPress blog and the corresponding MySQL database running in Docker containers. If not, see section "Migrate your blog to Docker", to see how to move your existing blog into a Docker container within minutes.

### Step 1: Create and run a backup container linked to your WordPress and MySQL containers

```bash
docker run \
    --name backup-my-blog \
    --volumes-from=your-wordpress-container \
    --link=your-mysql-container:mysql \
    -d aveltens/wordpress-backup
```

Replace the following values according to your system:

- `your-wordpress-container`: The name of the Docker container hosting your blog
- `your-mysql-container`: The name of the Docker container hosting your blogs MySQL database

### Step 2: Backup your blog

```bash
docker exec backup-my-blog backup
```

Yep. That's all you need to create a complete backup of your blog HTML pages and database content. The backup is stored in the container, so you won't see any file on your host system for now, but we will come to this later.

### Step 3: Restore the backup from a specific day

```bash
docker exec backup-my-blog restore 20141114
```

Replace 20141114 by the date, you actually made a backup.

All backups are timestamped with the date of the backup. So your blog can move back to any day in history on that you created a backup. The format of the timestamp is `yyyyMMdd` (4 digit year, 2 digit month, 2 digit day). But I am sure you noticed that already.

## Environment variables

| Variable                   | Default     | Description |
|:---------------------------|------------:|:------------|
| `MYSQL_ENV_MYSQL_HOST`     | n/a         | The database hostname or IP address. |
| `MYSQL_PORT_3306_TCP_PORT` | `3306`      | The database port. |
| `MYSQL_ENV_MYSQL_DATABASE` | n/a         | The database name. |
| `MYSQL_ENV_MYSQL_USER`     | n/a         | The database user. |
| `MYSQL_ENV_MYSQL_PASSWORD` | n/a         | The database password. It is highly recommenced to use the Docker secret `MYSQL_ENV_MYSQL_PASSWORD_FILE` instead. |
| `BACKUP_TIME`              | `0 3 * * *` | The automatically scheduled backup time in cronjob format. The default means every day at 3 am. |
| `CLEANUP_OLDER_THAN`       | n/a         | The age of previous backups in days that can be removed during the next backup. In other words, during each backup, if this variable is set, all backups older than `CLEANUP_OLDER_THAN` days will be removed. |
| `BACKUP_TIMESTAMP`         | `+%Y%m%d`   | The timestamp format of the `date` command which will be added to each backup file. The default use the ISO format for a date like `20240628` for the 28th July 2024. |
| `BACKUP_FILES_UID`         | `0`         | UID of the created backup files. You could for example use the output of `id -u` of your host system to easily access the backup files in your local volume. |
| `BACKUP_FILES_GID`         | `0`         | GID of the created backup files. You could for example use the output of `id -g` of your host system to easily access the backup files in your local volume. |
| `TZ`                       | n/a         | The [timezone identifier](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) of the backup container. For example `Europe/Berlin`. This effects the server time. |

Some of the environment variables can also be passed as [Docker secrets](https://docs.docker.com/compose/use-secrets/). In this case add the suffix `_FILE` to the variable name. For example `MYSQL_ENV_MYSQL_PASSWORD` would be `MYSQL_ENV_MYSQL_PASSWORD_FILE` if you want to use it as a secret.

## Create and run the backup container

The Docker image is available on the public Docker hub under the name `aveltens/wordpress-backup` as well as on GitHub.

wordpress-backup is a separate container, performing backup and restore operations. The WordPress and MySQL containers of your blog are linked to wordpress-backup, but they are not modified in any way.

To run a backup container, you use the `docker run` command, linking your WordPress and MySQL containers:

```bash
docker run \
    --name <backup-container-name> \
    --volumes-from=<your-wordpress-container> \
    --link=<your-mysql-container>:mysql \
    -d aveltens/wordpress-backup
```

You have to replace the placeholders:

- `<backup-container-name>`: A name of your choice to identify the backup container
- `<your-wordpress-container>`: The name of the WordPress container
- `<your-mysql-container>`: The name of your MySQL container

You may also specify a volume to be able to access the backup files on the Docker host:

```bash
docker run \
    --name <backup-container-name> \
    -v </host/path/to/backups>:/backups \
    --volumes-from=<your-wordpress-container> \
    --link=<your-mysql-container>:mysql \
    -d aveltens/wordpress-backup
```

- `</host/path/to/backups>`: an absolute path on the system hosting the containers

After creating a backup you find the backup files on that path on your host system.

## Manual backup

To manually create a backup of your WordPress blog use `docker exec` to run the backup command:

```bash
docker exec <backup-container-name> backup
```

`<backup-container-name>`: The name you chose when you created the container with `docker run`.

> Note that `docker exec` requires at least Docker 1.3.

This will create two archive files under `/backups` in the container. If you mapped a volume you may see those files in the according directory on your host now. They should be named something like `backup_20141030.sql.bz2` and `backup_20141030.tar.gz`.

The number within the filenames is a date in the format `yyyyMMdd` (4 digit year, 2 digit month, 2 digit day). This means there can only be one backup per day. If you do multiple backups a day the files will be replaced by the latest backup.

> You do not have to backup manually. See section "Automatic backups".

## Restore

To restore a backup of your WordPress blog use `docker exec` to run the restore command:

```bash
docker exec <backup-container-name> restore <date>
```

- `<date>`: The timestamp of the backup to restore, in the format `yyyyMMdd`.

> Note that `docker exec` requires at least Docker 1.3.

This will restore the database as well as the HTML content of your WordPress installation.

## Automatic backups

Per default wordpress-backup will automatically create a backup at 03:00 am every day. You can adjust that time by setting a cron expression to the variable BACKUP_TIME when creating the container. E.g. the following statement will create a container that does a backup at 2:00 am every day:

```bash
docker run \
    --name <backup-container-name> \
    --volumes-from=<your-wordpress-container> \
    --link=<your-mysql-container>:mysql \
    -e "BACKUP_TIME=0 2 * * *" \
    -d aveltens/wordpress-backup
```

## Automatic cleanup

Per default, wordpress-backup will never delete your backup files, so you can do it yourself, if and when you like.

If you want to delete old backups automatically, you can set the environment variable `CLEANUP_OLDER_THAN` to a number of days. In that case wordpress-backup will automatically delete backup older than that, before doing the next backup.

For example `CLEANUP_OLDER_THAN=100` will delete any backups, that are older than 100 days, as soon as the next (manual or automatic) backup is done.

*Be aware that the cleanup process does use the unix file last modified date as reference, and not the date in the file name. So a backup called backup_20110101.sql.bz2 that was last modified yesterday, will be only 1 day old!*

## Migrate your blog to Docker

If your WordPress blog is not yet running in a Docker container, you can migrate it with a few simple steps.

1. Manually back up your database and files
2. Create WordPress and MySQL containers
3. Restore your backups to those containers with the help of wordpress-backup

### Step 1: Manually back up your database and files

Use the following command to back up your blog's HTML contents:

```bash
tar --create --gzip -vv \
    --directory="</path/to/wordpress>" \
    --file="</path/to/your/backups>/backup_0.tar.gz" "./"
```

...and this command to backup your blog's database:

```bash
mysqldump --add-drop-table \
    -u<wordpress-user> -p<wordpress-password> <wordpress-db> \
    bzip2 -c > </path/to/your/backups>/backup_0.sql.bz2`
```

You have to replace the placeholders in both commands:

- `</path/to/wordpress>`: The root directory of your WordPress installation.
- `</path/to/your/backups>`: The folder where you want to store the backup files.
- `<wordpress-db>`: The name of the WordPress database.
- `<wordpress-user>`: The database user that WordPress uses.
- `<wordpress-password>`: The password of the WordPress database user.

### Step 2: Starting your dockerized system

Create a MySQL container:

```bash
docker run \
    --name wordpress-db \
    -e MYSQL_ROOT_PASSWORD=<root-password> \
    -e MYSQL_USER=wordpress \
    -e MYSQL_PASSWORD=<user-password> \
    -e MYSQL_DATABASE=wordpress \
    -d mysql
```

Further explanation: <https://registry.hub.docker.com/_/mysql/>

Create a WordPress container:

```bash
docker run \
    --name wordpress \
    --link wordpress-db:mysql \
    -e WORDPRESS_DB_USER=wordpress \
    -e WORDPRESS_DB_PASSWORD=<user-password> \
    -e WORDPRESS_DB_NAME=wordpress \
    -p 8080:80 \
    -d wordpress
```

Further explanation: <https://registry.hub.docker.com/_/wordpress/>

You should have a fresh WordPress installation at <http://localhost:8080/> now. Do not touch it. We will restore your backup in the next step.

### Step 3: Restore your backups to those containers with the help of wordpress-backup

Create a wordpress-backup container:

```bash
docker run \
    --name wordpress-backup \
    -v <path/to/your/backups>:/backups \
    --volumes-from=wordpress \
    --link=wordpress-db:mysql \
    -d aveltens/wordpress-backup
```

> Replace <path/to/your/backups> with the actual path the backup files have been stored before.

...and finally restore your backup:

```bash
docker exec wordpress-backup restore 0
```

That's it! <http://localhost:8080/> should show your blog now.

## Docker Compose example

Take a look at [wordpress-backup-quickstart](https://github.com/angelo-v/wordpress-backup-quickstart) for a Docker Compose setup.

<!-- markdownlint-disable-next-line MD033 -->
<details><summary>Advanced docker compose example (using secrets)</summary>

Create a environment file `.env` including your personal settings:

```ini
DB_NAME=choose_your_db_name
DB_USER=choose_your_db_username
```

Create a secret file `.db-password.txt` just including your database password:

```txt
set_a_secure_user_password
```

Create the `docker-compose.yml` file:

```yml
services:

    wordpress:
        image: wordpress:6.5-php8.1
        restart: always
        ports:
            - 8080:80
        environment:
            WORDPRESS_DB_HOST: db
            WORDPRESS_DB_USER: "$DB_USER"
            WORDPRESS_DB_NAME: "$DB_NAME"
            WORDPRESS_DB_PASSWORD_FILE: /run/secrets/db_password
        volumes:
            - wordpress:/var/www/html
        secrets:
            - db_password

    db:
        image: mariadb:lts
        restart: always
        environment:
            MYSQL_DATABASE: "$DB_NAME"
            MYSQL_USER: "$DB_USER"
            MYSQL_PASSWORD_FILE: /run/secrets/db_password
            MYSQL_RANDOM_ROOT_PASSWORD: '1'
        volumes:
            - db:/var/lib/mysql
        secrets:
            - db_password

    backup:
        image: aveltens/wordpress-backup
        restart: always
        volumes:
            - ./backups:/backups
            - wordpress:/var/www/html
        depends_on:
            - db
        environment:
            MYSQL_ENV_MYSQL_HOST: db
            MYSQL_ENV_MYSQL_DATABASE: "$DB_NAME"
            MYSQL_ENV_MYSQL_USER: "$DB_USER"
            MYSQL_ENV_MYSQL_PASSWORD_FILE: /run/secrets/db_password
        secrets:
            - db_password

secrets:
    db_password:
        file: .db-password.txt

volumes:
    wordpress:
    db:
```

Now you are ready to start:

```bash
# depending on you setup it is
docker compose up -d
# or
docker-compose up -d
```

That's it! <http://localhost:8080/> should show your blog now.

</details>

## Source Code

The source code of wordpress-backup can be found at [GitHub](https://github.com/angelo-v/wordpress-backup)

## Contribute

If you want to contribute I am happy to merge your pull request!
If you do so, please ensure

- that all automated tests pass (run `./test.sh`)
- the documentation is updated (`README.md`)

## Contact

Please contact me for any questions & feedback: <angelo.veltens@online.de>

## License

The MIT License (MIT)

Copyright (c) 2015, Angelo Veltens

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
