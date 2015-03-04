#!/bin/bash -e

. scripts/init-cli.sh

DOCKER_CMD="docker run -i -t -v `pwd`:/usr/src $DOCKER_SUPERUSER"

case $MODE in
    BUILD_DOCKER_IMAGE)
	. scripts/build-docker-image.sh
	build_docker_image
	;;

    RUN_DOCKER)
	$DOCKER_CMD $DOCKER_CONTAINER \
	    ./build.sh -b $CODENAME $PACKAGE
	;;

    DOCKER_SHELL)
	$DOCKER_CMD $DOCKER_CONTAINER
	;;

    PREP_DEBIAN)
	if $IN_DOCKER; then
	    prep_debian
	else
	    $DOCKER_CMD -e IN_DOCKER=true $DOCKER_CONTAINER \
		./build.sh -p $CODENAME $PACKAGE
	fi
	;;

    BUILD_PACKAGE)
	. scripts/build-package.sh
	build_package
	build_deb_repo
	;;

    REPO_INIT)
	if $IN_DOCKER; then
	    . scripts/build-package.sh
	    init_deb_repo
	else
	    $DOCKER_CMD -e IN_DOCKER=true $DOCKER_CONTAINER \
		./build.sh -I $CODENAME $PACKAGE
	fi
	;;

    REPO_BUILD)
	if $IN_DOCKER; then
	    . scripts/build-package.sh
	    build_deb_repo
	else
	    $DOCKER_CMD -e IN_DOCKER=true $DOCKER_CONTAINER \
		./build.sh -B $CODENAME $PACKAGE
	fi
	;;

esac
