# SPDX-FileCopyrightText: 2015 Angelo Veltens <angelo.veltens@online.de>
#
# SPDX-License-Identifier: MIT

import docker
import pytest


@pytest.fixture(scope="session")
def client():
    return docker.from_env()


@pytest.fixture(scope="session")
def image(client):
    img, _ = client.images.build(path="./src")
    return img
