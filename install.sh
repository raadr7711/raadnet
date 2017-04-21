#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

temp="/tmp/unms-install"

args="$*"
version=""
branch="master"

branchRegex=" --branch ([^ ]+)"
if [[ "$args" =~ $branchRegex ]]; then
  branch="${BASH_REMATCH[1]}"
fi
echo branch="$branch"

repo="https://raw.githubusercontent.com/Ubiquiti-App/UNMS/${branch}"

versionRegex=" --version ([^ ]+)"
if [[ "$args" =~ $versionRegex ]]; then
  version="${BASH_REMATCH[1]}"
fi

if [ -z "$version" ]; then
  if ! version=$(curl -fsS "$repo/latest-version"); then
    echo "Failed to obtain latest version info"
    exit 1
  fi
fi
echo version="$version"

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
./install-full.sh $args --version "$version"

cd ~
if ! rm -rf $temp; then
  echo "Warning: Failed to remove temporary directory $temp"
fi
