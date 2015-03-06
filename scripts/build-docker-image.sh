debug "Sourcing build-docker-image.sh"
#
# These routines handle installing build deps, both those directly
# configured and those required by the source package. There are two
# stages:
#
# 1) (Before `docker build`) Prepare everything needed for the Docker
# build context.
#
# 2) (Inside `docker build`) Configure Apt and dpkg repos and arches,
# and install build dependencies.
#
# These routines are not shared with the Docker container package
# build.

###########################################
# Before Docker build

docker_build_render_dockerfile() {
    # Render Dockerfile template
    sed < $CONFIG_DIR/Dockerfile.tmpl > $DOCKER_DIR/Dockerfile \
	-e "s,@DOCKER_BASE@,${DOCKER_BASE}," \
	-e "s,@DOCKER_SRC_DIR@,${DOCKER_SRC_DIR}," \
	-e "s,@PACKAGE@,${PACKAGE},g" \
	-e "s,@CODENAME@,${CODENAME},g" \
	-e "s,@DEBUG_FLAG@,${DEBUG_FLAG},g"
}

docker_build_context_files() {
    # Copy scripts and build dependencies to Docker build context

    # Scripts
    cp -a build.sh $SCRIPTS_DIR $CONFIG_DIR $DOCKER_DIR/

    # Local build deps
    if test -n "$LOCAL_DEPS"; then
        # Copy dependency packages into container
	rm -rf $DOCKER_DIR/$REPO_DIR; mkdir -p $DOCKER_DIR/$REPO_DIR
	>$DOCKER_DIR/$REPO_DIR/overrides
	for i in $LOCAL_DEPS; do
	    eval "cp -a $REPO_DIR/pool/main/$i $DOCKER_DIR/$REPO_DIR"
	done
    fi
}

docker_build_prepare_context() {
    # This function preps the Docker context directory
    # (build/$PACKAGE/docker) with the Dockerfile, scripts, package
    # sources and build dependencies.
    #
    # Building the Docker context directory with only required files
    # instead of uploading the entire build directory, which could be
    # very large, saves time and resources

    msg "Building docker image"
    rm -rf $DOCKER_DIR; mkdir -p $DOCKER_DIR

    # Render Dockerfile
    docker_build_render_dockerfile

    # Copy files to Docker build context
    docker_build_context_files

    # Download source tarball and link into Docker context
    source_tarball_download
    source_tarball_docker_link

    # Update debianization from git and build tarball
    debianization_git_tree_update
    debianization_git_tree_pack

}

###########################################
# Inside Docker build

docker_image_extra_repos() {
    if declare -f distro_configure_repos >/dev/null; then
	msg "Configuring distro-specific third-party repos"
	distro_configure_repos

	msg "    Configured third-party keys:"
	apt-key --keyring /etc/apt/trusted.gpg list \
	    | awk '{ print "DEBUG:\t\t" $0 }' >&2
    else
	debug "No third-party repo config function supplied"
    fi
}

docker_image_local_repo() {
    # Configure local apt repo and add any extra packages

    if test -z "${EXTRA_BUILD_PACKAGES}"; then
	debug "No extra build packages specified; not building local repo"
	return
    fi

    msg "Installing extra build dependencies"

    # Build repo
    (
	cd $REPO_DIR
	for i in *.deb; do
	    dpkg-deb -W --showformat='${Package}\n' $i >> overrides
	done
	dpkg-scanpackages . overrides | gzip > Packages.gz
    )

    # Configure Apt
    echo 'deb file://$DOCKER_SRC_DIR/repo /' \
	> /etc/apt/sources.list.d/local.list
    repo $DOCKER_SRC_DIR/repo
}

docker_image_cross_build_arch() {
    msg "Adding package architectures:  $ARCHES"
    for arch in $ARCHES; do
	dpkg --add-architecture $arch
    done
}

docker_image_unpack_sources() {
    msg "Unpacking package sources for Docker image"

    # Unpack source tarball
    source_tarball_unpack
    # Unpack debianization tarball
    debianization_git_tree_unpack

    # Configure package
    configure_package_wrapper
}

docker_image_install_build_deps() {
    msg "Installing package build dependencies"

    # Update apt repos
    apt-get update

    # Install build deps
    (
	cd $BUILD_DIR
	yes | mk-build-deps -ir
    )

    # Install extra package deps (perhaps needed by configure step)
    if test -n "$EXTRA_BUILD_PACKAGES"; then
	debug "    Installing extra package deps"
	apt-get install -y --force-yes --no-install-recommends \
	    $EXTRA_BUILD_PACKAGES
    fi

    # Install cross-build tools
    if test -n "$CROSS_BUILD_PACKAGES"; then
	debug "    Installing cross-build packages"
	apt-get install -y --no-install-recommends \
	    $CROSS_BUILD_PACKAGES
    fi
}

docker_image_cleanup() {
    # Clean up build dir if not debugging
    if ! $DEBUG; then
	msg "Cleaning up build directory"
	rm -rf *
    else
	debug "Debug enabled; not cleaning build directory"
    fi
}