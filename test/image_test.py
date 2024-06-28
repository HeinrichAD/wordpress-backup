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
        ]
    )
    yield container
    container.remove(force=True)


def test_scripts_exist(host):
    assert host.file("/bin/backup").is_file
    assert host.file("/bin/restore").is_file


def test_installed_packages(host):
    assert host.package("cron").is_installed
    assert host.package("bzip2").is_installed
    assert host.package("mysql-client").is_installed


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
