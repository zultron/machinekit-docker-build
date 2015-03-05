# Defaults
TCL_VER=8.6

# Be sure package is valid for distro
PACKAGES=" $PACKAGES "
if test "$PACKAGES" = "${PACKAGES/ $PACKAGE /}"; then
    echo "Package '$PACKAGE' not valid for codename '$CODENAME'" >&2
    exit 1
fi

# Sources.list
if test -f configs/distro/$CODENAME.sources.list; then
    SOURCES_LIST="ADD	configs/distro/sources.list.${CODENAME}" \
	"/etc/apt/sources.list"
else
    SOURCES_LIST="# No extra sources.list"
fi

# Define pre_prep_debian if not already defined
declare -f pre_prep_debian >/dev/null || pre_prep_debian() {
    mkdir -p docker/repo docker/src
}

build_docker_image() {
    rm -rf docker; mkdir -p docker

    test -z "${EXTRA_BUILD_PACKAGES}" || \
	INSTALL_EXTRA_BUILD_PACKAGES="RUN	apt-get install -y --force-yes \
	    --no-install-recommends ${EXTRA_BUILD_PACKAGES}"
    # Render Dockerfile template
    sed < configs/Dockerfile.tmpl > docker/Dockerfile \
	-e "s,@PACKAGE@,${PACKAGE},g" \
	-e "s,@DOCKER_BASE@,${DOCKER_BASE}," \
	-e "s,@CODENAME@,${CODENAME},g" \
	-e "s,@SOURCES_LIST@,${SOURCES_LIST}," \
	-e "s,@KEY_IDS@,${KEY_IDS}," \
	-e "s,@TCL_VER@,${TCL_VER}," \
	-e "s,@EXTRA_BUILD_PACKAGES@,${INSTALL_EXTRA_BUILD_PACKAGES}," \
	-e "s,@DOCKER_SRC_DIR@,${DOCKER_SRC_DIR}," \

    # Copy build scripts; this gets around docker pre v1.1 with
    # no .dockerignore support (Trusty)
    cp -a build.sh scripts configs docker/

    rm -rf docker/repo; mkdir -p docker/repo
    if test -n "$LOCAL_DEPS"; then
	# Copy dependency packages into container
	for i in $LOCAL_DEPS; do
	    eval "cp -a repo/pool/main/$i docker/repo"
	done
	(
	    cd docker/repo
	    >overrides
	    for i in *.deb; do
		dpkg-deb -W --showformat='${Package}\n' $i >> overrides
	    done
	    dpkg-scanpackages . overrides | gzip > Packages.gz
	)
    fi

    # Run additional per-package prep
    pre_prep_debian

    # Build container
    docker build -t $DOCKER_CONTAINER docker
}
