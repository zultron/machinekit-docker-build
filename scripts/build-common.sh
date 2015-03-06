debug "Sourcing build-common.sh"
#
# These routines handle source tarballs and git debianization trees.
# They may be used both during the Docker image build (to generate and
# install build deps) and during the package build inside the Docker
# container.

########################################
# Source tarball operations
source_tarball_download() {
    if test -n "$TARBALL_URL"; then
	if test ! -f $BUILD_BASE_DIR/$DEBIAN_TARBALL; then
	    msg "    Downloading source tarball"
	    mkdir -p $SOURCE_DIR
	    wget $TARBALL_URL -O $BUILD_BASE_DIR/$DEBIAN_TARBALL
	else
	    debug "    Source tarball exists; not downloading"
	fi
    else
	debug "    No TARBALL_URL defined; not downloading source tarball"
    fi
}

source_tarball_docker_link() {
    if test -n "$TARBALL_URL"; then
	msg "    Linking source tarball"
	mkdir -p $DOCKER_DIR/$SOURCE_DIR
	rm -f $DOCKER_DIR/$BUILD_BASE_DIR/$DEBIAN_TARBALL
	ln $BUILD_BASE_DIR/$DEBIAN_TARBALL \
	    $DOCKER_DIR/$BUILD_BASE_DIR/$DEBIAN_TARBALL
    fi
}

source_tarball_unpack() {
    msg "    Unpacking source tarball"
    rm -rf $BUILD_DIR; mkdir -p $BUILD_DIR
    tar xCf $BUILD_DIR $BUILD_BASE_DIR/$DEBIAN_TARBALL --strip-components=1
}


########################################
# Debianization git tree operations
debianization_git_tree_update() {
    if test -n "$GIT_URL"; then
	if test ! -d $GIT_DIR/$GIT_REPO; then
	    msg "    Cloning new debianization git tree"
	    (
		mkdir -p $GIT_DIR; cd $GIT_DIR
		git clone --depth=1 $GIT_URL
	    )
	elif ! $IN_DOCKER; then  # git fails in chroot
	    msg "    Updating debianization git tree"
	    (
		cd $GIT_DIR/$GIT_REPO
		git pull --ff-only
	    )
	else
	    debug "    Not updating debianization git tree; inside chroot"
	fi
    else
	debug "    No GIT_URL defined; not handling debianization git tree"
    fi
}

debianization_git_tree_unpack() {
    if test -n "$GIT_URL"; then
	if test $MODE = PREP_DEBIAN; then
	    # Debianization is copied into chroot with `git archive`
	    msg "    Unpacking debianization from git tree tarball"
	    mkdir -p $BUILD_DIR/debian
	    tar xCf $BUILD_DIR/debian $SOURCE_DIR/$DEBZN_TARBALL

	else
	    # Outside chroot, copy directly from git tree
	    msg "    Copying debianization from git tree"
	    mkdir -p $BUILD_DIR/debian
	    git --git-dir=$GIT_DIR/$GIT_REPO/.git archive --prefix=./ HEAD | \
		tar xCf $BUILD_DIR/debian -
	fi
    else
	debug "    No GIT_URL defined; not unpacking debianization from git"
    fi
}

debianization_git_tree_pack() {
    if test -n "$GIT_URL"; then
	msg "    Building debianization tarball from git tree"
	git --git-dir=$GIT_DIR/$GIT_REPO/.git archive HEAD | \
	    gzip > $DOCKER_DIR/$SOURCE_DIR/$DEBZN_TARBALL
    else
	debug "    No GIT_URL defined; not unpacking debianization from git"
    fi
}

########################################
# Package configuration

configure_package_wrapper() {
    # Some packages may define a configuration step
    if declare -f configure_package >/dev/null; then
	msg "    Configuring package"
	configure_package
    else
	debug "    No configure_package function defined"
    fi
}
