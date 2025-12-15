# nmap-static-binaries
<<<<<<< HEAD

Pivoting with static binaries

# Linux Arch Types

Updated versin of nmap is x86_64 from github

There are 2 different version of static nmap binaries, one is for x86 architectures and the other is for x64.  Included in the repository are two .gz files that have already been compiled with version 7.93 of Nmap.  If you don't need to modify the nmap version, you can just grab those two .gz files in the release area and unarchive them on your target.

# Compiling

Included in the repository is a docker file and build.sh for compiling the static binaries.  The latest version of nmap (7.91) was used in the nmap.tar.gz archives for x86.
The latest version from gitlab was used for the x86_64 version.  All previous version are also available in the archives.

```sh
docker build . -t nmap-build
docker run --rm -v ${PWD}/:/output/ nmap-build
```
The executables will be in the output directory

## Building for ARM64

If you want to build static ARM64 (aarch64) binaries, there is a dedicated Dockerfile and helper script.

Requirements: Docker Buildx and QEMU emulation enabled (Docker Desktop typically supports this).

To build and extract the ARM64 binaries:

```sh
# Build the ARM64 image and load it locally
docker buildx build --platform linux/arm64 -t nmap-build-arm64 -f Dockerfile.aarch64 --load .

# Run the container (use --platform to ensure it runs under the right emulation if needed)
mkdir -p output
docker run --rm --platform linux/arm64 -v ${PWD}/output:/output nmap-build-arm64
```

You can also use the provided `build-arm64.sh` helper, which performs the build and run steps.

Artifacts will be under `output/Linux/<arch>` (e.g. `output/linux/aarch64`), matching `uname -m` reported by the container.

## Building for ARM32 (armhf)

If you want to build static ARM32 (armhf/armv7l) binaries, there is a dedicated Dockerfile and helper script.

Requirements: Docker Buildx and QEMU emulation enabled (Docker Desktop typically supports this).

To build and extract the ARM32 binaries:

```sh
# Build the ARM32 image and load it locally
docker buildx build --platform linux/arm/v7 -t nmap-build-arm32 -f Dockerfile.armhf --load .

# Run the container (use --platform to ensure it runs under the right emulation if needed)
mkdir -p output
docker run --rm --platform linux/arm/v7 -v ${PWD}/output:/output nmap-build-arm32
```

You can also use the provided `build-arm32.sh` helper, which performs the build and run steps.

Artifacts will be under `output/Linux/<arch>` (e.g. `output/linux/armv7l`), matching `uname -m` reported by the container.

## Host detection and cross-compile modes

The provided scripts can detect your host architecture and pick an appropriate strategy:

- If your host is the same architecture as the target (e.g., building on an aarch64 host), the per-arch scripts will perform a native build using that Dockerfile.
- If you're on a different host, the scripts will prefer Docker Buildx to build using QEMU emulation (recommended).
- If Buildx is not available, the scripts fall back to a cross-compile Docker image that uses cross compiler toolchains (`Dockerfile.cross`).

Commands:

```sh
# Build a specific arch (with auto host detection / buildx fallback)
./build-arm64.sh
./build-arm32.sh

# Build everything (prefers host-native for same arch, buildx where available, and falls back to cross-compile Dockerfile)
./build-all.sh

# Cross-build using a Debian container with cross toolchains (no qemu needed)
./build-cross.sh
```

Notes:

- Docker Buildx + QEMU provides convenience but may be slower due to emulation. The cross-compile Dockerfile avoids QEMU by using native cross toolchains installed in the container.
- When cross-compiling, we set environment variables in the build container so OpenSSL and Nmap configure steps use the cross toolchains.

Advanced: CROSS_HOST and TARGET_ARCH

If you prefer to use the `build.sh` entrypoint, set the `CROSS_HOST` and `TARGET_ARCH` environment variables when running a container to force cross-build behavior.

Examples:

```sh
# Force cross-compile using CROSS_HOST in a build container
docker run --rm -e CROSS_HOST=aarch64-linux-gnu -e TARGET_ARCH=aarch64 -v ${PWD}/output:/output nmap-build-cross

# Or use the helper to cross-compile all arches
./build-cross.sh
```


# Usage

## scan.sh

The script scan.sh takes the ip address as an argument.  The script will execute 3 different types of scans concurrently:

1.  quick TCP nmap scan
2.  Top 20 UDP scan
3.  Full TCP scan

When all the scans are complete, the shell script will archive the resulting scans in the output folder, with the name nmap-scan-<IP>.tar.gz

The shell script is executed as follows:

scan.sh \<IP Address of Target\>

*Example*

```sh
scan.sh 192.168.0.1
```

## scan-port.sh

This script does a detailed scan of the target by port number and script type.  As with the scan.sh, the output is then archived in the output directory with the name nmap-scan-port-\<IP\>.tar.gz

The shell script is executed as follows:

scan-port.sh \<IP Address of Target\> \<PORT Number\> \<NSE Script to execute\>

*Example*

```
scan-port.sh 192.168.0.1 80 "http*, banner, vuln"
```

## full-scan.sh

This script will perform the same initial scans as the scan.sh script, but will also scan ports that are found by the quick scans.
***NOTE:*** Quick scanning will only pull the most popular ports, there for the full scan may miss some ports found by the full scan.

The shell scrip is executed as follows:

full-scan.sh \<IP Address of Target\>

As with the other scripts, the output is then archived in the output directory with the name nmap-scan-\<IP\>.tar.gz
The individual port scans run the following NSE scripts: default, banner, vuln

*Example*

```
full-scan.sh 192.168.0.1
```

## Inside the Archive, naming convention

- Quick Scans
  - \<IP\>_quick_tcp_nmap.txt
- UDP Top 20
  - \<IP\>_top_20_udp_nmap.txt
- Full TCP Scan
  - \<IP\>_full_tcp_nmap.txt
- Individual Port Scans
  - \<IP\>_tcp\_\<port\>_nmap.txt

# Dependencies

This repository now includes local copies of dependencies to ensure reproducible builds and offline capability.

## Local Dependencies

The build process uses local copies of dependencies located in the `deps/` directory instead of downloading them during build time:

### OpenSSL
- Version: 1.1.1w
- Used for SSL/TLS functionality in nmap

### Nmap Source Code  
- Version: Latest from GitHub (bleeding edge)
- The complete nmap source repository

This provides:
- Reproducible builds
- Offline build capability
- Version control over dependencies  
- Faster build times
- Consistent source across all builds

See `deps/README.md` for more information about managing dependencies.

# Credits

The build scripts are taken from Andrew-d's github page at https://github.com/andrew-d/static-binaries

Build scripts modified by opinfosec on 28-Oct-22
- Added removing of shared in libz
- Modified nmap version to latest from github
- Updated OpenSSL to 1.1.1q

Additional modifications:
- Added local dependency management (OpenSSL and Nmap)
- Updated all build scripts and Dockerfiles to use local copies
- Eliminated external dependencies during build process
