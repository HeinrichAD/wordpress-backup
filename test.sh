#!/bin/sh

# SPDX-FileCopyrightText: 2015 Angelo Veltens <angelo.veltens@online.de>
#
# SPDX-License-Identifier: MIT

docker run --rm -t \
  -v "$(pwd):/project" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  aveltens/docker-testinfra
