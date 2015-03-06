debug "Sourcing build-docker-image.sh"
#
# These routines handle unpacking sources to generate build deps
# during the Docker image build.  There are two stages:
#
# 1) (Before `docker build`) Download sources and put into Docker
#    image build context
#
# 2) (During `docker build`) Unpack sources and debian files and
#    optionally configure the package.
#
# These routines are not shared with the Docker container package
# build.

# Defaults
TCL_VER=8.6

# Be sure package is valid for distro
PACKAGES=" $PACKAGES "
if test "$PACKAGES" = "${PACKAGES/ $PACKAGE /}"; then
    echo "Package '$PACKAGE' not valid for codename '$CODENAME'" >&2
    exit 1
fi

# Sources.list
if test -f $DISTRO_CONFIG_DIR/$CODENAME.sources.list; then
    SOURCES_LIST="ADD	$DISTRO_CONFIG_DIR/sources.list.${CODENAME}" \
	"/etc/apt/sources.list"
else
    SOURCES_LIST="# No extra sources.list"
fi

docker_image_build() {
    msg "Building docker image"
    rm -rf $DOCKER_DIR; mkdir -p $DOCKER_DIR

    test -z "${EXTRA_BUILD_PACKAGES}" || \
	INSTALL_EXTRA_BUILD_PACKAGES="RUN	apt-get install -y --force-yes \
	    --no-install-recommends ${EXTRA_BUILD_PACKAGES}"
    # Render Dockerfile template
    sed < $CONFIG_DIR/Dockerfile.tmpl > $DOCKER_DIR/Dockerfile \
	-e "s,@PACKAGE@,${PACKAGE},g" \
	-e "s,@DOCKER_BASE@,${DOCKER_BASE}," \
	-e "s,@CODENAME@,${CODENAME},g" \
	-e "s,@SOURCES_LIST@,${SOURCES_LIST}," \
	-e "s,@KEY_IDS@,${KEY_IDS}," \
	-e "s,@TCL_VER@,${TCL_VER}," \
	-e "s,@EXTRA_BUILD_PACKAGES@,${INSTALL_EXTRA_BUILD_PACKAGES}," \
	-e "s,@DOCKER_SRC_DIR@,${DOCKER_SRC_DIR},g" \
	-e "s,@SOURCE_DIR@,${SOURCE_DIR},g" \
	-e "s,@BUILD_DIR@,${BUILD_DIR},g" \
	-e "s,@REPO_DIR@,${REPO_DIR},g" \
	-e "s,@SCRIPTS_DIR@,${SCRIPTS_DIR},g" \
	-e "s,@CONFIG_DIR@,${CONFIG_DIR},g" \
	-e "s,@GIT_DIR@,${GIT_DIR},g" \
	-e "s,@DEBUG_FLAG@,${DEBUG_FLAG},g" \

    # Copy build scripts; this gets around docker pre v1.1 with
    # no .dockerignore support (Trusty)
    cp -a build.sh $SCRIPTS_DIR $CONFIG_DIR $DOCKER_DIR/

    (
	rm -rf $DOCKER_DIR/$REPO_DIR; mkdir -p $DOCKER_DIR/$REPO_DIR
	>$DOCKER_DIR/$REPO_DIR/overrides
	cd $DOCKER_DIR/$REPO_DIR
	if test -n "$LOCAL_DEPS"; then
	# Copy dependency packages into container
	    for i in $LOCAL_DEPS; do
		eval "cp -a ../../$REPO_DIR/pool/main/$i ."
	    done
	    for i in *.deb; do
		dpkg-deb -W --showformat='${Package}\n' $i >> overrides
	    done
	fi
	dpkg-scanpackages . overrides | gzip > Packages.gz
    )

    # Download source tarball and link into Docker context
    source_tarball_download
    source_tarball_docker_link

    # Update debianization from git and build tarball
    debianization_git_tree_update
    debianization_git_tree_pack

    # Build container
    docker build -t $DOCKER_CONTAINER $DOCKER_DIR
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
