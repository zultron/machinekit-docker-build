#!/bin/bash -e

. scripts/init-cli.sh

case $MODE in
    BUILD_DOCKER_IMAGE) # -i: Build docker image
	if ! $IN_DOCKER; then
	    # First, before Docker build:
	    #
	    # Prepare Docker context
	    docker_build_prepare_context
	    # Build container
	    docker build -t $DOCKER_CONTAINER $DOCKER_BUILD_DEBUG_FLAG \
		$DOCKER_DIR
	else
	    # Then, inside Docker build:
	    #
	    # Configure third-party repos
	    docker_image_extra_repos
	    # Configure local apt repo
	    docker_image_local_repo
	    # Configure cross-build architectures
	    docker_image_cross_build_arch
	    # Unpack and configure source package
	    docker_image_unpack_sources
	    # Install build dependencies
	    docker_image_install_build_deps
	    # Clean up
	    docker_image_cleanup
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
