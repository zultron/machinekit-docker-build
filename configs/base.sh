# Repo with various packages
GITHUB_REPO=https://github.com/zultron

# Where to put files in the Docker container
DOCKER_SRC_DIR=/usr/src/docker-build

# Where source tarballs live
SOURCE_DIR=src/$PACKAGE

# Where git sources live
GIT_DIR=git

# Where sources are built
BUILD_DIR=build/$PACKAGE

# Docker run command
DOCKER_CMD="docker run -i -t -v `pwd`:$DOCKER_SRC_DIR $DOCKER_SUPERUSER"

# Debianization tarball
DEBZN_TARBALL=$PACKAGE.debian.tar.gz
