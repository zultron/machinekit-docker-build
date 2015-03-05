debug "Sourcing configs/package/linux.sh"

VERSION=3.8.13
RELEASE=11
TARBALL=linux-${VERSION}.tar.xz
TARBALL_URL=http://www.kernel.org/pub/linux/kernel/v3.0/${TARBALL}
DEBIAN_TARBALL=linux_$VERSION.orig.tar.xz
DEBIAN_PKG_URL=https://github.com/zultron/linux-ipipe-deb/archive/${VERSION}.tar.gz
GIT_URL=https://github.com/zultron/linux-ipipe-deb.git
GIT_REPO=linux-ipipe-deb
LOCAL_DEPS="
    x/xenomai/xenomai-kernel-source_*.deb
    r/rtai/rtai-source_*.deb
    r/rtai/python-rtai_*_all.deb
"

FEATURESETS="xenomai rtai"
DISABLED_FEATURESETS=""  # Set to 'xenomai' or 'rtai' to skip build

# The Debian Linux package naming scheme is a small nightmare
LINUX_SUBVER=$(echo $VERSION | sed 's/\.[0-9]*$$//')
LINUX_PKG_ABI=1
LINUX_PKG_EXTENSION=${LINUX_SUBVER}-${LINUX_PKG_ABI}

ARCH=amd64  # FIXME:  need all arches

BINARY_PACKAGES="
    linux-support-${LINUX_PKG_EXTENSION}_${VERSION}-${RELEASE}_all.deb"
for fs_base in $FEATURESETS; do
    case $ARCH in
	amd64) fs=${fs_base}.x86; flav=amd64; arch=$ARCH ;;
	i386) fs=${fs_base}.x86; flav=686-pae; arch=$ARCH ;;
	armhf.bbb) fs=${fs_base}.beaglebone; flav=omap; arch=armhf ;;
	armhf.rpi) fs=${fs_base}.raspberry; flav=rpi; arch=armhf ;; # FIXME
    esac
    PKG_SUFF=${VERSION}-${RELEASE}_${arch}.deb
    BINARY_PACKAGES+="
	linux-image-${LINUX_PKG_EXTENSION}-${fs}-${flav}_${PKG_SUFF}
	linux-headers-${LINUX_PKG_EXTENSION}-${fs}-${flav}_${PKG_SUFF}
	linux-headers-${LINUX_PKG_EXTENSION}-common-${fs}_${PKG_SUFF}
    "  # FIXME:  need to filter packages for each arch
done

EXTRA_BUILD_PACKAGES=python
# Add xenomai-kernel-source if not disabled
DISABLED_FEATURESETS=" $DISABLED_FEATURESETS "
test "${DISABLED_FEATURESETS/xenomai/}" != "$DISABLED_FEATURESETS" || \
EXTRA_BUILD_PACKAGES+=" xenomai-kernel-source"
# Add rtai-source if not disabled
DISABLED_FEATURESETS=" $DISABLED_FEATURESETS "
test "${DISABLED_FEATURESETS/rtai/}" != "$DISABLED_FEATURESETS" || \
EXTRA_BUILD_PACKAGES+=" rtai-source"

# Disable any requested featuresets
disable_featureset() {
    fs=$1
    sed -i 's/^\( *'$fs'$\)/#\1/' debian/config/defines
}

get_sources() {
    if test ! -f $SOURCE_DIR/$TARBALL; then
	mkdir -p $SOURCE_DIR
	wget $TARBALL_URL -O $SOURCE_DIR/$TARBALL
    fi

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

    # Configure package
    for featureset in $DISABLED_FEATURESETS; do
	disable_featureset $featureset
    done
    (
	cd $SOURCE_DIR
	debian/rules debian/control NOFAIL=true
    )
}

unpack_source() {
    get_sources

    rm -rf $BUILD_DIR; mkdir -p $BUILD_DIR/debian
    rm -f build/$DEBIAN_TARBALL; ln $SOURCE_DIR/$TARBALL build/$DEBIAN_TARBALL
    tar xCf $BUILD_DIR $SOURCE_DIR/$TARBALL --strip-components=1

    git --git-dir=$GIT_DIR/$GIT_REPO/.git archive --prefix=./ HEAD | \
	tar xCf $BUILD_DIR/debian -

    for featureset in $DISABLED_FEATURESETS; do
	(
	    cd $BUILD_DIR
	    disable_featureset $featureset
	)
    done

    (
	cd $BUILD_DIR
	debian/rules debian/control NOFAIL=true
    )
}
