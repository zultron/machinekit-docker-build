GIT_REV=a416758
VERSION=4.0.5.${GIT_REV}
RELEASE=1
TARBALL=rtai-${RTAI_VERSION}.tar.gz
TARBALL_URL=https://github.com/ShabbyX/RTAI/archive/${GIT_REV}.tar.gz
DEBIAN_TARBALL=rtai_$VERSION.orig.tar.gz
SOURCE_DIR=src

DSC_FILE=${PACKAGE}_${VERSION}.dsc

BINARY_PACKAGES="
    rtai-source_${VERSION}-${RELEASE}_*.deb
    librtai-dev_${VERSION}-${RELEASE}_*.deb
    librtai1_${VERSION}-${RELEASE}_*.deb
    rtai_${VERSION}-${RELEASE}_*.deb
    python-rtai_${VERSION}-${RELEASE}_all.deb
    rtai-doc_${VERSION}-${RELEASE}_all.deb
"

prep_debian() {
    mkdir -p debian
    wget https://github.com/zultron/rtai-deb/archive/master.tar.gz
    tar xCf debian master.tar.gz --strip-components=1
}

unpack_source() {
    if ! test -f src/rtai/$DEBIAN_TARBALL; then
	mkdir -p src/rtai
	wget -O src/rtai/$DEBIAN_TARBALL $TARBALL_URL
    fi
    rm -rf src/rtai/$SOURCE_DIR
    mkdir -p src/rtai/$SOURCE_DIR
    tar xCf src/rtai/$SOURCE_DIR src/rtai/$DEBIAN_TARBALL --strip-components=1

    ls -l
    
    (
	wget https://github.com/zultron/rtai-deb/archive/master.tar.gz \
	    -O src/rtai/debian.tar.gz
	mkdir -p src/rtai/$SOURCE_DIR/debian
	tar xCf src/rtai/$SOURCE_DIR/debian src/rtai/debian.tar.gz \
	    --strip-components=1
    )
}
