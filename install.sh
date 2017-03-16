#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

repo="https://raw.githubusercontent.com/Ubiquiti-App/UNMS/master"
temp="/tmp/unms-install"

args="$*"
version=""

if [[ "$args" =~ ^[0-9] ]]; then
  read -r version args <<< "$args"
fi

if [ -z "$version" ]; then
  if ! version=$(curl -fsS "$repo/latest-version"); then
    echo "Failed to obtain latest version info"
    exit 1
  fi
fi

echo version="$version"
echo args="$args"

rm -rf $temp
if ! mkdir $temp; then
  echo "Failed to create temporary directory"
  exit 1
fi
cd $temp


echo "Downloading installation package for version $version."
if ! curl -sS "$repo/unms-$version.tar.gz" | tar xz; then
  echo "Failed to download installation package"
  exit 1
fi

chmod +x install-full.sh
./install-full.sh --version "$version" $args

cd ~
if ! rm -rf $temp; then
  echo "Warning: Failed to remove temporary directory $temp"
fi
