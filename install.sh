#!/bin/bash

GIT_BRANCH='master'
GIT_URL="https://raw.githubusercontent.com/Ubiquiti-App/UNMS/$GIT_BRANCH"

PATH="$PATH:/usr/local/bin"

# linux user for UNMS docker containers
USERNAME="unms"
#POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 48 | head -n 1);
#SECRET=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 48 | head -n 1);
if [ -z "$INSTALL_CLOUD" ]; then INSTALL_CLOUD=false; fi

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
}

create_user() {
	if [ -z "$(getent passwd $USERNAME)" ]; then
		echo "Creating user $USERNAME."
		useradd -m $USERNAME
		usermod -aG docker $USERNAME
	fi
}

download_docker_compose_files() {
	if [ ! -f /home/$USERNAME/docker-compose.yml ]; then
		echo "Downloading docker compose files."
		curl -o /home/$USERNAME/docker-compose.yml $GIT_URL/docker-compose.yml
#		curl -o /home/$USERNAME/docker-compose.migrate.yml $GIT_URL/docker-compose.migrate.yml
#		curl -o /home/$USERNAME/docker-compose.env $GIT_URL/docker-compose.env

#		echo "Replacing env in docker compose."
#		sed -i -e "s/POSTGRES_PASSWORD=ucrmdbpass1/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/g" /home/$USERNAME/docker-compose.env
#		sed -i -e "s/SECRET=changeThisSecretKey/SECRET=$SECRET/g" /home/$USERNAME/docker-compose.env

#		change_port
#		change_suspend_port
#		enable_ssl
	fi
}

#change_port() {
#	local PORT
#
#	while true; do
#		if [ "$INSTALL_CLOUD" = true ]; then
#			PORT=y
#		else
#			read -r -p "Do you want UNMS to be accessible on port 80? (Yes: recommended for most users, No: will set 8080 as default) [Y/n]: " PORT
#		fi
#
#		case $PORT in
#			[yY][eE][sS]|[yY])
#				sed -i -e "s/- 8080:80/- 80:80/g" /home/$USERNAME/docker-compose.yml
#				sed -i -e "s/- 8443:443/- 443:443/g" /home/$USERNAME/docker-compose.yml
#				echo "UNMS will start at 80 port."
#				echo "#used only in instalation" >> /home/$USERNAME/docker-compose.env
#				echo "SERVER_PORT=80" >> /home/$USERNAME/docker-compose.env
#				break;;
#			[nN][oO]|[nN])
#				echo "UNMS will start at 8080 port. If you will change it, edit your docker-compose.yml in $USERNAME home directory."
#				echo "#used only in instalation" >> /home/$USERNAME/docker-compose.env
#				echo "SERVER_PORT=8080" >> /home/$USERNAME/docker-compose.env
#				break;;
#			*)
#				;;
#		esac
#	done
#}

#change_suspend_port() {
#	local PORT
#
#	while true; do
#		if [ "$INSTALL_CLOUD" = true ]; then
#			PORT=y
#		else
#			read -r -p "Do you want UNMS suspend page to be accessible on port 81? (Yes: recommended for most users, No: will set 8081 as default) [Y/n]: " PORT
#		fi
#
#		case $PORT in
#			[yY]*)
#				sed -i -e "s/- 8081:81/- 81:81/g" /home/$USERNAME/docker-compose.yml
#				echo "UCRM suspend page will start at 81 port."
#				echo "#used only in instalation" >> /home/$USERNAME/docker-compose.env
#				echo "SERVER_SUSPEND_PORT=81" >> /home/$USERNAME/docker-compose.env
#				break;;
#			[nN]*)
#				echo "UCRM suspend page will start at 8081 port. If you will change it, edit your docker-compose.yml in $USERNAME home direcotry."
#				echo "#used only in instalation" >> /home/$USERNAME/docker-compose.env
#				echo "SERVER_SUSPEND_PORT=8081" >> /home/$USERNAME/docker-compose.env
#				break;;
#			*)
#				;;
#		esac
#	done
#}

#enable_ssl() {
#	local SSL
#
#	while true; do
#		if [ "$INSTALL_CLOUD" = true ]; then
#			SSL=y
#		else
#			read -r -p "Do you want to enable SSL? (You need to generate a certificate for yourself) [Y/n]: " SSL
#		fi
#
#		case $SSL in
#			[yY]*)
#				enable_server_name
#				change_ucrm_ssl_port
#				break;;
#			[nN]*)
#				echo "UCRM has disabled support for SSL."
#				break;;
#			*)
#				;;
#		esac
#	done
#}

#enable_server_name() {
#	local SERVER_NAME_LOCAL
#
#	if [ "$INSTALL_CLOUD" = true ]; then
#		if [ -f "$CLOUD_CONF" ]; then
#			cat "$CLOUD_CONF" >> /home/$USERNAME/docker-compose.env
#		fi
#	else
#		read -r -p "Enter Server domain name for UCRM, for example ucrm.example.com: " SERVER_NAME_LOCAL
#		echo "SERVER_NAME=$SERVER_NAME_LOCAL" >> /home/$USERNAME/docker-compose.env
#	fi
#}

#change_ucrm_ssl_port() {
#	local PORT
#
#	while true; do
#		if [ "$INSTALL_CLOUD" = true ]; then
#			PORT=y
#		else
#			read -r -p "Do you want UCRM SSL to be accessible on port 443? (Yes: recommended for most users, No: will set 8443 as default) [Y/n]: " PORT
#		fi
#
#		case $PORT in
#			[yY]*)
#				sed -i -e "s/- 8443:443/- 443:443/g" /home/$USERNAME/docker-compose.yml
#				echo "UCRM SSL will start at 443 port."
#				break;;
#			[nN]*)
#				echo "UCRM SSL will start at 8443 port."
#				break;;
#			*)
#				;;
#		esac
#	done
#}

download_docker_images() {
	echo "Downloading docker images."
	cd /home/$USERNAME && /usr/local/bin/docker-compose pull
}

start_docker_images() {
	echo "Starting docker images."
	cd /home/$USERNAME && \
#	/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.migrate.yml run migrate_app && \
	/usr/local/bin/docker-compose up -d && \
	/usr/local/bin/docker-compose ps
}

check_system
install_docker
install_docker_compose
create_user
download_docker_compose_files
download_docker_images
start_docker_images

exit 0
