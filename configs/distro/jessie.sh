debug "Sourcing configs/distro/jessie.sh"

# RT kernel packages
PACKAGES="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
PACKAGES+=" czmq"
# Misc
PACKAGES+=" libwebsockets jansson python-pyftpdlib"
# Zultron Debian package repo
PACKAGES+=" dovetail-automata-keyring"

# Docker
DOCKER_BASE=debian:jessie

# Distros
KEY_IDS=7F32AE6B73571BB9
