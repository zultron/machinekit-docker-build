# Build Machinekit Packages in Docker

These scripts build Machinekit and dependency packages inside of
Docker containers.

For each package, the scripts build a Docker container image for a
particular distro with all build deps pre-installed. This is done by
unpacking and configuring package sources and running `mk-build-deps`
so that when a package's build deps change, the Docker image may be
updated simply by rebuilding.

These scripts are then run in the resulting container to prepare the
sources and build the packages.

The idea is that the Docker container provides a canned, reproducible
build environment that can be set up and torn down easily.
Cross-compilation will also be possible from the same Docker
container. Package sources can then be quickly modified, and
automatically configured and rebuilt from original sources without the
hassle of setting up the build environment. This will make it easier
for new users to build Machinekit, make it easier for ARM users to
cross-compile Machinekit, and make it easier to contribute to the
dependency packages.

## Adding a package

### Variables

(To be written)

### Functions

`pre_prep_debian`:  This function should fetch/update package sources
and make them available in the Docker context, probably in the
`docker/src` directory, where they will be available during the Docker
image build.

## Flow

In all cases, start by processing command-line options, performing
sanity checks, setting default variables, and reading 'configs'.

Configs are really shell scripts that set variables and define
functions for each distro and for each package.

### Docker container image build

    ./build.sh -i jessie linux

Outside Docker, prepare files for `docker build`:
- Render `Dockerfile` template
- Copy scripts and configs into Docker context
- Build a package repository for locally-build deps, if needed
- Run package-specific `pre_prep_debian` prep script, if needed
  - Fetch source tarballs
  - Clone and/or update git trees
  - Put sources in Docker context
- Run `docker build`

Docker image build:
- Starts from an official distro image on the Docker hub
- Installs a base set of packages
- Copies scripts, sources and repo into container
- Installs the locally-built package dependency repo
- `build.sh -p`:  Unpack and configure source package
- Install package build dependencies with `mk-build-deps`

### Package build

Builds the package:
- Unpacks sources
- Runs `dpkg-buildpackage`

Updates Apt package repository:
- Initializes repo, if necessary
- Adds source package
- Add binary package(s)

## Packages

### Linux with ipipe-based real-time extensions

The Debian Linux kernel package is difficult to rebuild.  It requires
initial configuration before its build, and requires separate
`linux-tools` and `linux-latest` companion packages to be configured
and built separately.

Although the package has the 'featureset' facility for special builds
with different patch sets (the `linux-rt` kernel with `RT_PREEMPT` is
an example), the Xenomai and RTAI extensions include extensive
run-time support that is best packaged separately.  The run-time
systems must be kept in sync with the associated kernel patches.  This
introduces additional complication when building the kernel, since
kernel patches are generated from the Xenomai and RTAI package builds,
and become additional kernel package dependencies.

The kernel package depends on the `xenomai-kernel-source` and
`rtai-source` packages, not only during the build like most build
dependencies, but also during the *configure* step.

The `linux` package configuration scripts here account for this extra
wrinkle, working in concert with the `[linux-ipipe-deb]` Debian kernel
packaging with 'featureset-friendly' modifications and rules for
configuring and building Xenomai and RTAI packages.

They make the `xenomai-kernel-source` and `rtai-source` packages
available during the Docker image build for the package configuration.

In addition, these scripts also configure and build the `linux-tools`
and `linux-latest` packages that accompany the main kernel packages.

[linux-ipipe-deb]: https://github.com/zultron/linux-ipipe-deb/

## TODO

- Add changelog entry; see `dpkg-buildpackage(1)`
- Cross-build
- Multi-arch
- Remove a level from git directory
- Auto-gen source tarball name; account for native packages
