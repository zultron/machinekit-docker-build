# Print info messages
msg() {
    echo -e "INFO:  $@" >&2
}

debug() {
    if $DEBUG; then
	echo -e "DEBUG:  $@" >&2
    fi
}

usage() {
    test -z "$1" || msg "$1"
    msg "Usage:"
    msg "    $0 -i | -r | -s [-d] CODENAME PACKAGE"
    msg "        -i:	Build docker image"
    msg "        -r:	Run package build"
    msg "        -s:	Spawn interactive shell in docker container"
    msg "        -S:	Run as superuser"
    msg "        -d:	Print verbose debug output"
    exit 1
}

mode() {
    test $MODE = "$1" -o \( -z "$1" -a $MODE != NONE \) || return 1
    return 0
}

# Process command line opts
MODE=NONE
DOCKER_SUPERUSER="-u `id -u`"
DEBUG=false
while getopts irspbIBSd ARG; do
    # $OPTARG
    case $ARG in
	i) MODE=BUILD_DOCKER_IMAGE ;;
	r) MODE=RUN_DOCKER ;;
	s) MODE=DOCKER_SHELL ;;
	p) MODE=PREP_DEBIAN ;;
	b) MODE=BUILD_PACKAGE ;;
	I) MODE=REPO_INIT ;;
	B) MODE=REPO_BUILD ;;
	S) DOCKER_SUPERUSER='' ;;
	d) DEBUG=true ;;
        *) usage
    esac
done
shift $((OPTIND-1))

# Must be a mode and two non-flag args
mode && test $# = 2 || usage

# CL args
CODENAME="$1"
PACKAGE="$2"

# Check codename
test -f configs/distro/$CODENAME.sh || \
    usage "Codename '$CODENAME' not valid"

# Check package
test -f configs/package/$PACKAGE.sh || \
    "Package '$PACKAGE' not valid"

# Set variables
DOCKER_CONTAINER=$CODENAME-$PACKAGE
test -n "$IN_DOCKER" || IN_DOCKER=false

# Debug info
debug "Mode: $MODE"

# Source configs
. configs/base.sh  # Init below variables
. $DISTRO_CONFIG_DIR/$CODENAME.sh
. $PACKAGE_CONFIG_DIR/$PACKAGE.sh

# Source scripts
. $SCRIPTS_DIR/build-common.sh
. $SCRIPTS_DIR/build-docker-image.sh
. $SCRIPTS_DIR/build-package.sh


# Debug
set -x
