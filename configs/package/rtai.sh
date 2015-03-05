debug "Sourcing configs/package/rtai.sh"

GIT_REV=a416758
VERSION=4.0.5.${GIT_REV}
RELEASE=1
TARBALL_URL=https://github.com/ShabbyX/RTAI/archive/${GIT_REV}.tar.gz
DEBIAN_TARBALL=rtai_$VERSION.orig.tar.gz
TARBALL=$DEBIAN_TARBALL
GIT_URL=https://github.com/zultron/rtai-deb.git
GIT_REPO=rtai-deb

BINARY_PACKAGES="
    rtai-source_${VERSION}-${RELEASE}_*.deb
    librtai-dev_${VERSION}-${RELEASE}_*.deb
    librtai1_${VERSION}-${RELEASE}_*.deb
    rtai_${VERSION}-${RELEASE}_*.deb
    python-rtai_${VERSION}-${RELEASE}_all.deb
    rtai-doc_${VERSION}-${RELEASE}_all.deb
"

get_sources() {
    # Source tarball
    if test ! -f $SOURCE_DIR/$TARBALL; then
	mkdir -p $SOURCE_DIR
	wget $TARBALL_URL -O $SOURCE_DIR/$TARBALL
    fi

    # Debianization git tree
    if test ! -d $GIT_DIR/$GIT_REPO; then
	(
	    mkdir -p git; cd git
	    git clone --depth=1 $GIT_URL
	)
    elif ! $IN_DOCKER; then  # git won't work in chroot
	(
	    cd $GIT_DIR/$GIT_REPO
	    git pull
	)
    fi
}

pre_prep_debian() {
    get_sources

    mkdir -p docker/$SOURCE_DIR
    ln $SOURCE_DIR/$TARBALL docker/$SOURCE_DIR/$TARBALL

    git --git-dir=$GIT_DIR/$GIT_REPO/.git archive HEAD | \
	gzip > docker/$SOURCE_DIR/$DEBZN_TARBALL
}

prep_debian() {
    # Source tarball
    mkdir -p $SOURCE_DIR
    tar xCf $SOURCE_DIR $SOURCE_DIR/$TARBALL --strip-components=1

    # /debian
    mkdir -p $SOURCE_DIR/debian
    tar xCf $SOURCE_DIR/debian $SOURCE_DIR/$DEBZN_TARBALL
}

unpack_source() {
    get_sources

    rm -rf $BUILD_DIR; mkdir -p $BUILD_DIR/debian
    rm -f $BUILD_BASE_DIR/$DEBIAN_TARBALL
    ln $SOURCE_DIR/$TARBALL $BUILD_BASE_DIR/$DEBIAN_TARBALL
    tar xCf $BUILD_DIR $SOURCE_DIR/$TARBALL --strip-components=1

    git --git-dir=$GIT_DIR/$GIT_REPO/.git archive --prefix=./ HEAD | \
	tar xCf $BUILD_DIR/debian -
}
