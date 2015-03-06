#!/bin/bash -e

. scripts/init-cli.sh

case $MODE in
    BUILD_DOCKER_IMAGE) # -i: Build docker image
	if ! $IN_DOCKER; then
	    docker_image_build
	else
	    docker_image_unpack_sources
	fi
	;;

    BUILD_PACKAGE) # -b:  Build package in Docker container
	if ! $IN_DOCKER; then
	    # Re-run ourself in Docker
	    $DOCKER_CMD -e IN_DOCKER=true $DOCKER_CONTAINER \
		./build.sh -b $DEBUG_FLAG $CODENAME $PACKAGE
	else
	    build_package
	    build_deb_repo
	fi
	;;

    DOCKER_SHELL) # -s: Spawn interactive shell in docker container
	$DOCKER_CMD $DOCKER_CONTAINER
	;;

    REPO_INIT) # -I
	if $IN_DOCKER; then
	    init_deb_repo
	else
	    $DOCKER_CMD -e IN_DOCKER=true $DOCKER_CONTAINER \
		./build.sh -I $DEBUG_FLAG $CODENAME $PACKAGE
	fi
	;;

    REPO_BUILD) # -B
	if $IN_DOCKER; then
	    build_deb_repo
	else
	    $DOCKER_CMD -e IN_DOCKER=true $DOCKER_CONTAINER \
		./build.sh -B $DEBUG_FLAG $CODENAME $PACKAGE
	fi
	;;

esac
