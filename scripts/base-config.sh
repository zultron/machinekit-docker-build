# Repo with various packages
GITHUB_REPO=https://github.com/zultron

# Top-level directory for builds
BUILD_BASE_DIR=build/$PACKAGE

# Where to put files in the Docker container
DOCKER_SRC_DIR=/usr/src/docker-build

# Where source tarballs live
SOURCE_DIR=$BUILD_BASE_DIR/src

# Where git sources live
GIT_DIR=$BUILD_BASE_DIR/git

# Where sources are built
BUILD_DIR=$BUILD_BASE_DIR/build

# Where the Apt package repo is built
REPO_DIR=repo

# Where the Docker context is built
DOCKER_DIR=$BUILD_BASE_DIR/docker

# Docker run command
DOCKER_CMD="docker run -i -t -v `pwd`:$DOCKER_SRC_DIR $DOCKER_SUPERUSER"

# Debug flag for passing to docker and scripts
DEBUG_FLAG="`$DEBUG && echo -d`"
DOCKER_BUILD_DEBUG_FLAG="`$DEBUG && echo --force-rm=false`"

# Debianization tarball
DEBZN_TARBALL=$PACKAGE.debian.tar.gz


# Scripts and configs directories
SCRIPTS_DIR=scripts
CONFIG_DIR=configs
DISTRO_CONFIG_DIR=$SCRIPTS_DIR/distro
PACKAGE_CONFIG_DIR=$SCRIPTS_DIR/package


# TCL default version; override in distro config
TCL_VER=8.6
