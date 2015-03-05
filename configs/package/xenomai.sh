debug "Sourcing configs/package/xenomai.sh"

VERSION=2.6.3
TARBALL=xenomai-$VERSION.tar.bz2
TARBALL_URL=http://download.gna.org/xenomai/stable/$TARBALL
DEBIAN_TARBALL=xenomai_$VERSION.tar.bz2
DPKG_BUILD_ARGS=-Zbzip2


BINARY_PACKAGES="
    libxenomai-dev_${VERSION}_*.deb
    libxenomai1_${VERSION}_*.deb
    xenomai-doc_${VERSION}_all.deb
    xenomai-kernel-source_${VERSION}_all.deb
    xenomai-runtime_${VERSION}_*.deb
"

pre_prep_debian() {
    source_tarball_download
    source_tarball_docker_link
}

prep_debian() {
    source_tarball_unpack
}

unpack_source() {
    source_tarball_download
    source_tarball_docker_link
    source_tarball_unpack
}
