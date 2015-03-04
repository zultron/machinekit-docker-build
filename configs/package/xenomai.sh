VERSION=2.6.3
TARBALL=xenomai-$VERSION.tar.bz2
TARBALL_URL=http://download.gna.org/xenomai/stable/$TARBALL
DEBIAN_TARBALL=xenomai_$VERSION.tar.bz2
SOURCE_DIR=xenomai-$VERSION
DPKG_BUILD_ARGS=-Zbzip2

DSC_FILE=${PACKAGE}_${VERSION}.dsc

BINARY_PACKAGES="
    libxenomai-dev_${VERSION}_*.deb
    libxenomai1_${VERSION}_*.deb
    xenomai-doc_${VERSION}_all.deb
    xenomai-kernel-source_${VERSION}_all.deb
    xenomai-runtime_${VERSION}_*.deb
"

prep_debian() {
    mkdir debian
    wget -O debian/control \
	http://git.xenomai.org/xenomai-2.6.git/plain/debian/control?id=v$VERSION
}

unpack_source() {
    if ! test -f src/xenomai/$DEBIAN_TARBALL; then
	mkdir -p src/xenomai
	wget -O src/xenomai/$DEBIAN_TARBALL $TARBALL_URL
    fi
    rm -rf src/xenomai/$SOURCE_DIR
    tar xCf src/xenomai src/xenomai/$DEBIAN_TARBALL
}
