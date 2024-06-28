# SPDX-FileCopyrightText: 2015 Angelo Veltens <angelo.veltens@online.de>
#
# SPDX-License-Identifier: MIT

import pytest


testinfra_hosts = ['docker://test_container']


@pytest.fixture(scope="module", autouse=True)
def container(client, image):
    container = client.containers.run(
        image.id,
        name="test_container",
        detach=True,
        environment=[
            'MYSQL_ENV_MYSQL_HOST=mariadb',
            'MYSQL_ENV_MYSQL_USER=test_user',
            'MYSQL_ENV_MYSQL_DATABASE=test_db',
            'MYSQL_ENV_MYSQL_PASSWORD=test_password',
            'BACKUP_TIME=1 2 3 4 5',
            'CLEANUP_OLDER_THAN=100'
        ]
    )
    yield container
    container.remove(force=True)


def test_environment(host):
    env = host.check_output("env")
    assert "MYSQL_ENV_MYSQL_HOST=mariadb" in env
    assert "MYSQL_ENV_MYSQL_USER=test_user" in env
    assert "MYSQL_ENV_MYSQL_DATABASE=test_db" in env
    assert "MYSQL_ENV_MYSQL_PASSWORD=test_password" in env
    assert "BACKUP_TIME=1 2 3 4 5" in env
    assert "CLEANUP_OLDER_THAN=100" in env


def test_mysql_configuration(host):
    file = host.file("/etc/mysql/conf.d/mysqlpassword.cnf")
    assert file.is_file
    assert file.content_string == '''; backup settings
[mysqldump]
host="mariadb"
user="test_user"
password="test_password"

; restore settings
[mysql]
host="mariadb"
user="test_user"
password="test_password"
'''


def test_crontab(host):
    assert host.check_output("crontab -l") == "1 2 3 4 5 backup > /backups/last-backup.log 2>&1"
