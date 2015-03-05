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

pre_prep_debian() {
    source_tarball_download
    source_tarball_docker_link

    debianization_git_tree_update
    debianization_git_tree_pack
}

prep_debian() {
    source_tarball_unpack
    debianization_git_tree_unpack
}

unpack_source() {
    source_tarball_download
    source_tarball_docker_link
    source_tarball_unpack

    debianization_git_tree_update
    debianization_git_tree_unpack
}
