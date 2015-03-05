build_package() {
    unpack_source
    pushd $BUILD_DIR
    dpkg-buildpackage -uc -us $DPKG_BUILD_ARGS
    popd
}

REPODIR=$(readlink -f repo)
REPREPRO="reprepro -VV -b ${REPODIR} \
    --confdir +b/conf-${CODENAME} --dbdir +b/db-${CODENAME}"

init_deb_repo() {
    if test ! -f ${REPODIR}/conf-${CODENAME}/distributions; then
	mkdir -p ${REPODIR}/conf-${CODENAME}
	
	sed < configs/ppa-distributions.tmpl \
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

    # /tmp/machinekit/machinekit-deb-dependency-autobuilder/Makefile

    # add source pkg
    test -n "$DSC_FILE" || \
	DSC_FILE=${PACKAGE}_${VERSION}${RELEASE:+-$RELEASE}.dsc
    ${REPREPRO} \
	removesrc ${CODENAME} ${PACKAGE}

    ${REPREPRO} -C main \
	includedsc ${CODENAME} \
	build/${DSC_FILE}

    # remove src pkg
	    # ${REPREPRO} -T dsc \
	    # 	remove ${CODENAME} $($(1)_SOURCE_NAME)

    # remove bin pkg
	    # ${REPREPRO} -T deb \
	    # 	$$(if $$(filter-out $$(ARCH),$$(BUILD_INDEP_ARCH)),-A $$(ARCH)) \
	    # 	remove ${CODENAME} $$(call REPREPRO_PKGS,$(1),$$(ARCH))

    # add bin pkg
    (
	cd build
	${REPREPRO} -C main includedeb ${CODENAME} \
	    ${BINARY_PACKAGES}
    )
}
