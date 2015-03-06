debug "Sourcing build-package.sh"
#
# These routines handle building the package in the Docker container.
# They are called directly with this directory bind-mounted in the
# container.
#
# They are not used in the Docker image build.

# Entry point into package build from Docker container
build_package() {
    msg "Building package '$PACKAGE'"
    # Download source tarball and unpack
    source_tarball_download
    source_tarball_unpack

    # Update debianization git tree and copy to source tree
    debianization_git_tree_update
    debianization_git_tree_unpack

    # Some packages may define a configuration step
    configure_package_wrapper

    # Build package
    (
	cd $BUILD_DIR
	dpkg-buildpackage -uc -us $DPKG_BUILD_ARGS
    )
}

REPODIR=$(readlink -f $REPO_DIR)
REPREPRO="reprepro -VV -b ${REPODIR} \
    --confdir +b/conf-${CODENAME} --dbdir +b/db-${CODENAME}"

init_deb_repo() {
    if test ! -f ${REPODIR}/conf-${CODENAME}/distributions; then
	msg "Initializing Debian Apt package repository"
	mkdir -p ${REPODIR}/conf-${CODENAME}
	
	sed < $CONFIG_DIR/ppa-distributions.tmpl \
	    > ${REPODIR}/conf-${CODENAME}/distributions \
	    -e "s/@codename@/${CODENAME}/g"
	${REPREPRO} export ${CODENAME}
    fi
}

list_deb_repo() {
    ${REPREPRO} \
	list ${CODENAME}
}

build_deb_repo() {
    # init Debian repo, if applicable
    init_deb_repo

    msg "Updating Debian Apt package repository"

    # add source pkg
    test -n "$DSC_FILE" || \
	DSC_FILE=${PACKAGE}_${VERSION}${RELEASE:+-$RELEASE}.dsc
    ${REPREPRO} \
	removesrc ${CODENAME} ${PACKAGE}

    ${REPREPRO} -C main \
	includedsc ${CODENAME} \
	$BUILD_BASE_DIR/${DSC_FILE}

    # remove src pkg
	    # ${REPREPRO} -T dsc \
	    # 	remove ${CODENAME} $($(1)_SOURCE_NAME)

    # remove bin pkg
	    # ${REPREPRO} -T deb \
	    # 	$$(if $$(filter-out $$(ARCH),$$(BUILD_INDEP_ARCH)),-A $$(ARCH)) \
	    # 	remove ${CODENAME} $$(call REPREPRO_PKGS,$(1),$$(ARCH))

    # add bin pkg
    (
	cd $BUILD_BASE_DIR
	${REPREPRO} -C main includedeb ${CODENAME} \
	    ${BINARY_PACKAGES}
    )
}
