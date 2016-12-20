#!/bin/sh

which docker

if [ $? = 0 ]; then
        docker-compose stop
        docker-compose rm -f -a
        docker rmi --force $(docker images -a | grep "^ubnt/unms" | awk '{print $3}')

        echo "Removed UNMS docker containers and images."
else
        echo "Docker not installed, nothing to uninstall."
fi
