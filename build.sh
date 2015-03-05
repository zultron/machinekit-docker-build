#!/bin/bash -e

. scripts/init-cli.sh

case $MODE in
    BUILD_DOCKER_IMAGE)
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
	build_package
	build_deb_repo
	;;

    REPO_INIT)
	if $IN_DOCKER; then
	    init_deb_repo
	else
	    $DOCKER_CMD -e IN_DOCKER=true $DOCKER_CONTAINER \
		./build.sh -I $CODENAME $PACKAGE
	fi
	;;

    REPO_BUILD)
	if $IN_DOCKER; then
	    build_deb_repo
	else
	    $DOCKER_CMD -e IN_DOCKER=true $DOCKER_CONTAINER \
		./build.sh -B $CODENAME $PACKAGE
	fi
	;;

esac
