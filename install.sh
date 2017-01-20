#!/bin/bash
PATH="$PATH:/usr/local/bin"

# linux user for UNMS docker containers
USERNAME="unms"

# parse arguments
VERSION="latest"
PROD="true"
DEMO="false"
DOCKER_IMAGE="ubnt/unms"
DOCKER_USERNAME=""
DOCKER_PASSWORD=""
HOME_DIR="/home/$USERNAME"
CONFIG_DIR="$HOME_DIR/conf"
DATA_DIR="$HOME_DIR/data"
GIT_URL="https://raw.githubusercontent.com/Ubiquiti-App/UNMS/master"
GIT_TOKEN=""
PACKAGE="install.tar.gz"

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --dev)
    echo "Setting PROD=false"
    PROD="false"
    ;;
    --demo)
    echo "Setting DEMO=true"
    DEMO="true"
    ;;
    -v|--version)
    echo "Setting VERSION=$2"
    VERSION="$2"
    shift # past argument value
    ;;
    --docker-image)
    echo "Setting DOCKER_IMAGE=$2"
    DOCKER_IMAGE="$2"
    shift # past argument value
    ;;
    --docker-username)
    echo "Setting DOCKER_USERNAME=$2"
    DOCKER_USERNAME="$2"
    shift # past argument value
    ;;
    --docker-password)
    echo "Setting DOCKER_PASSWORD=*****"
    DOCKER_PASSWORD="$2"
    shift # past argument value
    ;;
    --config-dir)
    echo "Setting CONFIG_DIR=$2"
    CONFIG_DIR="$2"
    shift # past argument value
    ;;
    --data-dir)
    echo "Setting DATA_DIR=$2"
    DATA_DIR="$2"
    shift # past argument value
    ;;
    --git-url)
    echo "Setting GIT_URL=$2"
    GIT_URL="$2"
    shift # past argument value
    ;;
    --git-token)
    echo "Setting GIT_TOKEN=*****"
    GIT_TOKEN="$2"
    shift # past argument value
    ;;
    *)
    # unknown option
    ;;
esac
shift # past argument key
done

export VERSION
export DEMO
export PROD
export DOCKER_IMAGE
export DATA_DIR
export CONFIG_DIR

check_system() {
  local lsb_dist
  local dist_version

  if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
    lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
  fi

  if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
    lsb_dist='debian'
  fi

  if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
    lsb_dist='fedora'
  fi

  if [ -z "$lsb_dist" ] && [ -r /etc/oracle-release ]; then
    lsb_dist='oracleserver'
  fi

  if [ -z "$lsb_dist" ]; then
    if [ -r /etc/centos-release ] || [ -r /etc/redhat-release ]; then
    lsb_dist='centos'
    fi
  fi

  if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
    lsb_dist="$(. /etc/os-release && echo "$ID")"
  fi

  lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

  case "$lsb_dist" in

    ubuntu)
    if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
      dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
    fi
    ;;

    debian)
    dist_version="$(cat /etc/debian_version | sed 's/\/.*//' | sed 's/\..*//')"
    ;;

    *)
    if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
      dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
    fi
    ;;

  esac

  if [ "$lsb_dist" = "ubuntu" ] && [ "$dist_version" != "xenial" ] || [ "$lsb_dist" = "debian" ] && [ "$dist_version" != "8" ]; then
    echo "Unsupported distro."
    echo "Supported was: Ubuntu Xenial and Debian 8."
    echo $lsb_dist
    echo $dist_version
    exit 1
  fi
}

install_docker() {
  which docker > /dev/null 2>&1

  if [ $? = 1 ]; then
    echo "Download and install Docker"
    curl -fsSL https://get.docker.com/ | sh
  fi

  which docker > /dev/null 2>&1

  if [ $? = 1 ]; then
    echo "Docker not installed. Please check previous logs. Aborting."
    exit 1
  fi
}

install_docker_compose() {
  which docker-compose > /dev/null 2>&1

  if [ $? = 1 ]; then
    echo "Download and install Docker compose."
    curl -L https://github.com/docker/compose/releases/download/1.9.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi

  which docker-compose > /dev/null 2>&1

  if [ $? = 1 ]; then
    echo "Docker compose not installed. Please check previous logs. Aborting."
    exit 1
  fi

  DOCKER_COMPOSE_VERSION=`docker-compose -v | sed 's/.*version \([0-9]*\.[0-9]*\).*/\1/'`;
  DOCKER_COMPOSE_MAJOR=${DOCKER_COMPOSE_VERSION%.*}
  DOCKER_COMPOSE_MINOR=${DOCKER_COMPOSE_VERSION#*.}

  if [ ${DOCKER_COMPOSE_MAJOR} -lt 2 ] && [ ${DOCKER_COMPOSE_MINOR} -lt 9 ] || [ ${DOCKER_COMPOSE_MAJOR} -lt 1 ]; then
    echo "Docker compose version $DOCKER_COMPOSE_VERSION is not supported. Please upgrade to version 1.9 or newer and try again."
    exit 1
  fi
}

create_user() {
  if [ -z "$(getent passwd $USERNAME)" ]; then
    echo "Creating user $USERNAME."

    useradd -m $USERNAME
    if [ $? = 1 ]; then
      echo "Failed to create user '$USERNAME'"
      exit 1
    fi

    usermod -aG docker $USERNAME
    if [ $? = 1 ]; then
      echo "Failed to add user '$USERNAME' to docker group."
      exit 1
    fi
  fi
}

download_package() {
  echo "Downloading installation package."
  if [[ $GIT_TOKEN ]]; then
    curl -H "Authorization: token $GIT_TOKEN" -o "$HOME_DIR/$PACKAGE" $GIT_URL/$PACKAGE
  else
    curl -o "$HOME_DIR/$PACKAGE" $GIT_URL/$PACKAGE
  fi

  if [ $? = 1 ]; then
    echo "Failed to download installation package $PACKAGE"
    exit 1
  fi
}

extract_package() {
  echo "Extracting installation package."
  cd "$HOME_DIR"
  tar -xvzf "$PACKAGE"
  if [ $? = 1 ]; then
    echo "Failed to extract installation package $PACKAGE"
    exit 1
  fi
  rm "$PACKAGE"
}

download_docker_images() {
  echo "Downloading docker images."
  cd "$HOME_DIR"
  if [[ $DOCKER_USERNAME ]]; then
    docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD" -e="dummy"
  fi
  /usr/local/bin/docker-compose pull
  if [ $? = 1 ]; then
    echo "Failed to pull docker images"
    exit 1
  fi
}

create_data_volumes() {
  echo "Creating data volumes."
  mkdir -p $DATA_DIR/cert
  mkdir -p $DATA_DIR/images
  mkdir -p $DATA_DIR/config-backups
  mkdir -p $DATA_DIR/unms-backups
  mkdir -p $DATA_DIR/logs
  chown -R 1000 $DATA_DIR/*
}

start_docker_containers() {
  echo "Starting docker containers."
  cd "$HOME_DIR" && \
  /usr/local/bin/docker-compose up -d
  if [ $? = 1 ]; then
    echo "Failed to start docker containers"
    exit 1
  fi

  /usr/local/bin/docker-compose ps
}

check_system
install_docker
install_docker_compose
create_user
download_package
extract_package
download_docker_images
create_data_volumes
start_docker_containers

exit 0
