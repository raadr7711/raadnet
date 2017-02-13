#!/bin/bash
set -o nounset
set -o errexit

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
HTTP_PORT="80"
HTTPS_PORT="443"
PUBLIC_HTTPS_PORT=""
BEHIND_REVERSE_PROXY="false"
SSL_CERT_DIR=""
SSL_CERT=""
SSL_CERT_KEY=""
SSL_CERT_CA=""

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
    --behind-reverse-proxy)
    echo "Setting BEHIND_REVERSE_PROXY=true"
    BEHIND_REVERSE_PROXY="true"
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
    --http-port)
    echo "Setting HTTP_PORT=$2"
    HTTP_PORT="$2"
    shift # past argument value
    ;;
    --https-port)
    echo "Setting HTTPS_PORT=$2"
    HTTPS_PORT="$2"
    shift # past argument value
    ;;
    --public-https-port)
    echo "Setting PUBLIC_HTTPS_PORT=$2"
    PUBLIC_HTTPS_PORT="$2"
    shift # past argument value
    ;;
    --ssl-cert-dir)
    echo "Setting SSL_CERT_DIR=$2"
    SSL_CERT_DIR="$2"
    shift # past argument value
    ;;
    --ssl-cert)
    echo "Setting SSL_CERT=$2"
    SSL_CERT="$2"
    shift # past argument value
    ;;
    --ssl-cert-key)
    echo "Setting SSL_CERT_KEY=$2"
    SSL_CERT_KEY="$2"
    shift # past argument value
    ;;
    --ssl-cert-ca)
    echo "Setting SSL_CERT_CA=$2"
    SSL_CERT_CA="$2"
    shift # past argument value
    ;;
    *)
    # unknown option
    ;;
esac
shift # past argument key
done

if [ -z $PUBLIC_HTTPS_PORT ]; then
  PUBLIC_HTTPS_PORT="$HTTPS_PORT"
fi

export VERSION
export DEMO
export PROD
export DOCKER_IMAGE
export DATA_DIR
export CONFIG_DIR
export HTTP_PORT
export HTTPS_PORT
export PUBLIC_HTTPS_PORT
export BEHIND_REVERSE_PROXY
export SSL_CERT
export SSL_CERT_KEY
export SSL_CERT_CA

check_system() {
  local lsb_dist=""
  local dist_version=""

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
  if ! which docker > /dev/null 2>&1; then
    echo "Download and install Docker"
    curl -fsSL https://get.docker.com/ | sh
  fi

  if ! which docker > /dev/null 2>&1; then
    echo "Docker not installed. Please check previous logs. Aborting."
    exit 1
  fi
}

install_docker_compose() {
  if ! which docker-compose > /dev/null 2>&1; then
    echo "Download and install Docker compose."
    curl -L https://github.com/docker/compose/releases/download/1.9.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi

  if ! which docker-compose > /dev/null 2>&1; then
    echo "Docker compose not installed. Please check previous logs. Aborting."
    exit 1
  fi

  DOCKER_COMPOSE_VERSION=`docker-compose -v | sed 's/.*version \([0-9]*\.[0-9]*\).*/\1/'`;
  DOCKER_COMPOSE_MAJOR=${DOCKER_COMPOSE_VERSION%.*}
  DOCKER_COMPOSE_MINOR=${DOCKER_COMPOSE_VERSION#*.}

  if [ ${DOCKER_COMPOSE_MAJOR} -lt 2 ] && [ ${DOCKER_COMPOSE_MINOR} -lt 9 ] || [ ${DOCKER_COMPOSE_MAJOR} -lt 1 ]; then
    echo "Docker compose version $DOCKER_COMPOSE_VERSION is not supported. Please upgrade to version 1.9 or newer."
    read -p "Would you like to upgrade Docker compose automatically? [y/N]" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      if ! curl -L "https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
        echo "Docker compose upgrade failed. Aborting."
        exit 1
      fi
      chmod +x /usr/local/bin/docker-compose
    else
      exit 1
    fi
  fi
}

create_user() {
  if [ -z "$(getent passwd $USERNAME)" ]; then
    echo "Creating user $USERNAME."

    if ! useradd -m $USERNAME; then
      echo "Failed to create user '$USERNAME'"
      exit 1
    fi

    if ! usermod -aG docker $USERNAME; then
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
}

extract_package() {
  echo "Extracting installation package."
  cd "$HOME_DIR"
  if ! tar -xvzf "$PACKAGE"; then
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
  if ! /usr/local/bin/docker-compose pull; then
    echo "Failed to pull docker images"
    exit 1
  fi
}

create_data_volumes() {
  echo "Creating data volumes."

  if [ -z $SSL_CERT_DIR ]; then
    mkdir -p $DATA_DIR/cert
  else
    rm -rf $DATA_DIR/cert
    if ! ln -sT "$SSL_CERT_DIR" $DATA_DIR/cert; then
      echo "Failed to create a symlink to $SSL_CERT_DIR"
      exit 1
    fi
  fi
  mkdir -p $DATA_DIR/images
  mkdir -p $DATA_DIR/config-backups
  mkdir -p $DATA_DIR/unms-backups
  mkdir -p $DATA_DIR/logs
  mkdir -p $DATA_DIR/postgres
  mkdir -p $DATA_DIR/redis
  mkdir -p $DATA_DIR/import

  chown -R 1000 $DATA_DIR/*
  chown -R 999 $DATA_DIR/redis
  chown -R 70 $DATA_DIR/postgres
}

backup_mongo() {
  if ! docker inspect unms-mongo &> /dev/null; then
    return 0
  fi

  if ! docker exec unms-mongo mongoexport --jsonArray --db unms --collection logs --out /data/db/logs.json; then
    echo "Failed to export logs from Mongo DB";
    exit 1
  fi
  if ! mv -fT $DATA_DIR/mongo/logs.json $DATA_DIR/import/logs.json; then
    echo "Failed to export logs from Mongo DB";
    exit 1
  fi

  if ! docker exec -t unms-mongo mongoexport --jsonArray --db unms --collection outages --out /data/db/outages.json; then
    echo "Failed to export outages from Mongo DB";
    exit 1
  fi
  if ! mv -fT $DATA_DIR/mongo/outages.json $DATA_DIR/import/outages.json; then
    echo "Failed to export outages from Mongo DB";
    exit 1
  fi

  echo "Stopping unms-mongo"
  docker stop unms-mongo
  echo "Removing unms-mongo"
  docker rm unms-mongo
  echo "Removing $DATA_DIR/mongo"
  rm -rf $DATA_DIR/mongo
}

start_docker_containers() {
  echo "Starting docker containers."
  cd "$HOME_DIR" && \
  if ! /usr/local/bin/docker-compose up -d; then
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
backup_mongo
start_docker_containers

exit 0
