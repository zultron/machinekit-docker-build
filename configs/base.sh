# Repo with various packages
GITHUB_REPO=https://github.com/zultron

# Where to put files in the Docker container
DOCKER_SRC_DIR=/usr/src/docker-build

# Where source tarballs live
SOURCE_DIR=src/$PACKAGE

# Where git sources live
GIT_DIR=git

# Where sources are built
BUILD_BASE_DIR=build
BUILD_DIR=$BUILD_BASE_DIR/$PACKAGE

# Where the Apt package repo is built
REPO_DIR=repo

# Docker run command
DOCKER_CMD="docker run -i -t -v `pwd`:$DOCKER_SRC_DIR $DOCKER_SUPERUSER"

# Debianization tarball
DEBZN_TARBALL=$PACKAGE.debian.tar.gz


# Scripts and configs directories
SCRIPTS_DIR=scripts
CONFIG_DIR=configs
DISTRO_CONFIG_DIR=$CONFIG_DIR/distro
PACKAGE_CONFIG_DIR=$CONFIG_DIR/package
