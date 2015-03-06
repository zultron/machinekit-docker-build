debug "Sourcing build-common.sh"

########################################
# Source tarball operations
source_tarball_download() {
    debug "Downloading source tarball"
    if test ! -f $SOURCE_DIR/$TARBALL; then
	mkdir -p $SOURCE_DIR
	wget $TARBALL_URL -O $SOURCE_DIR/$TARBALL
    fi
}

source_tarball_docker_link() {
    debug "Linking source tarball"
    mkdir -p $DOCKER_DIR/$SOURCE_DIR
    rm -f $DOCKER_DIR/$SOURCE_DIR/$TARBALL
    ln $SOURCE_DIR/$TARBALL $DOCKER_DIR/$SOURCE_DIR/$TARBALL
}

source_tarball_unpack() {
    debug "Unpacking source tarball"
    rm -rf $BUILD_DIR; mkdir -p $BUILD_DIR
    tar xCf $BUILD_DIR $SOURCE_DIR/$TARBALL --strip-components=1
}


########################################
# Debianization git tree operations
debianization_git_tree_update() {
    debug "Updating debianization git tree"
    if test ! -d $GIT_DIR/$GIT_REPO; then
	(
	    mkdir -p $GIT_DIR; cd $GIT_DIR
	    git clone --depth=1 $GIT_URL
	)
    elif ! $IN_DOCKER; then  # git fails in chroot
	(
	    cd $GIT_DIR/$GIT_REPO
	    git pull --ff-only
	)
    fi
}

debianization_git_tree_unpack() {
    debug "Unpacking debianization git tree"
    if test $MODE = PREP_DEBIAN; then
	# Debianization is copied into chroot with `git archive`
	mkdir -p $BUILD_DIR/debian
	tar xCf $BUILD_DIR/debian $SOURCE_DIR/$DEBZN_TARBALL

    else
	# Outside chroot, copy directly from git tree
	mkdir -p $BUILD_DIR/debian
	git --git-dir=$GIT_DIR/$GIT_REPO/.git archive --prefix=./ HEAD | \
	    tar xCf $BUILD_DIR/debian -
    fi
}

debianization_git_tree_pack() {
    debug "Packing debianization git tree"
    git --git-dir=$GIT_DIR/$GIT_REPO/.git archive HEAD | \
	gzip > $DOCKER_DIR/$SOURCE_DIR/$DEBZN_TARBALL
}
