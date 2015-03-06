debug "Sourcing configs/package/xenomai.sh"

VERSION=2.6.3
TARBALL_URL=http://download.gna.org/xenomai/stable/xenomai-$VERSION.tar.bz2
DEBIAN_TARBALL=xenomai_$VERSION.tar.bz2
DPKG_BUILD_ARGS=-Zbzip2


BINARY_PACKAGES="
    libxenomai-dev_${VERSION}_*.deb
    libxenomai1_${VERSION}_*.deb
    xenomai-doc_${VERSION}_all.deb
    xenomai-kernel-source_${VERSION}_all.deb
    xenomai-runtime_${VERSION}_*.deb
"
