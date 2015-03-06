# Print info messages
msg() {
    echo -e "INFO:	$@" >&2
}

debug() {
    if $DEBUG; then
	echo -e "DEBUG:	$@" >&2
    fi
}

usage() {
    test -z "$1" || msg "$1"
    msg "Usage:"
    msg "    $0 -i | -b | -s [-d] CODENAME PACKAGE"
    msg "        -i:	Build docker image"
    msg "        -b:	Run package build"
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
DDEBUG=false
while getopts ibsIBSd ARG; do
    # $OPTARG
    case $ARG in
	i) MODE=BUILD_DOCKER_IMAGE ;;
	b) MODE=BUILD_PACKAGE ;;
	s) MODE=DOCKER_SHELL ;;
	I) MODE=REPO_INIT ;;
	B) MODE=REPO_BUILD ;;
	S) DOCKER_SUPERUSER='' ;;
	d) ! $DEBUG || DDEBUG=true; DEBUG=true ;;
        *) usage
    esac
done
shift $((OPTIND-1))

# Must be a mode and two non-flag args
mode && test $# = 2 || usage

# CL args
CODENAME="$1"
PACKAGE="$2"

# Init variables
. scripts/base-config.sh

# Check codename
test -f $DISTRO_CONFIG_DIR/$CODENAME.sh || \
    usage "Codename '$CODENAME' not valid"

# Check package
test -f $PACKAGE_CONFIG_DIR/$PACKAGE.sh || \
    "Package '$PACKAGE' not valid"

# Set variables
DOCKER_CONTAINER=$CODENAME-$PACKAGE
test -n "$IN_DOCKER" || IN_DOCKER=false

# Debug info
debug "Mode: $MODE"

# Source configs
. $DISTRO_CONFIG_DIR/$CODENAME.sh
. $PACKAGE_CONFIG_DIR/$PACKAGE.sh

# Source scripts
. $SCRIPTS_DIR/build-common.sh
. $SCRIPTS_DIR/build-docker-image.sh
. $SCRIPTS_DIR/build-package.sh


# Debug
! $DDEBUG || set -x
