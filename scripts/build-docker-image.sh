debug "Sourcing build-docker-image.sh"

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

# Define pre_prep_debian if not already defined
declare -f pre_prep_debian >/dev/null || pre_prep_debian() {
    mkdir -p $DOCKER_DIR/$REPO_DIR $DOCKER_DIR/$SOURCE_DIR
}

build_docker_image() {
    debug "Building docker image"
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

    # Run additional per-package prep
    pre_prep_debian

    # Build container
    docker build -t $DOCKER_CONTAINER $DOCKER_DIR
}
