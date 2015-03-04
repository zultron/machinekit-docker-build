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

build_docker_image() {
    mkdir -p docker

    # Render Dockerfile template
    sed < configs/Dockerfile.tmpl > docker/Dockerfile \
	-e "s,@PACKAGE@,${PACKAGE},g" \
	-e "s,@DOCKER_BASE@,${DOCKER_BASE}," \
	-e "s,@CODENAME@,${CODENAME},g" \
	-e "s,@SOURCES_LIST@,${SOURCES_LIST}," \
	-e "s,@KEY_IDS@,${KEY_IDS}," \
	-e "s,@TCL_VER@,${TCL_VER}," \

    # Copy build scripts; this gets around docker pre v1.1 with
    # no .dockerignore support (Trusty)
    cp -a build.sh scripts configs docker/

    # Build container
    docker build -t $DOCKER_CONTAINER docker
}
