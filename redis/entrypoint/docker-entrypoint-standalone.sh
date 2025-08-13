#!/bin/sh
set -e
. /usr/local/bin/redis-setup.sh

echo "Running redis-server in standalone mode"
exec redis-server /redis.conf
