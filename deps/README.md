# Dependencies

This directory contains local copies of dependencies used during the build process.

## OpenSSL

The build process uses a local copy of OpenSSL instead of downloading it during build time. This provides:

- Reproducible builds
- Offline build capability  
- Version control over dependencies
- Faster build times

Current OpenSSL version: 1.1.1w

## Nmap

The build process uses a local copy of the nmap source code instead of cloning from GitHub during build time. This provides:

- Reproducible builds
- Offline build capability
- Version control over dependencies
- Faster build times
- Consistent source across all architecture builds

Current nmap version: Latest from GitHub (bleeding edge)

### Directory Structure

```
deps/
├── openssl-1.1.1w/          # OpenSSL source code
├── nmap/                     # Nmap source code (git repository)
└── README.md                 # This file
```

### Updating OpenSSL

To update to a newer version of OpenSSL:

1. Download the new version: `curl -LOk https://www.openssl.org/source/openssl-X.X.X.tar.gz`
2. Extract: `tar zxf openssl-X.X.X.tar.gz`
3. Update the `OPENSSL_VERSION` variable in the build scripts:
   - `build.sh`
   - `build-x86_64.sh` 
   - `build-arm64.sh`
4. Remove the old OpenSSL directory
5. Test the build process

### Updating Nmap

To update to a newer version of nmap:

1. Navigate to the nmap directory: `cd deps/nmap`
2. Pull the latest changes: `git pull origin master`
3. Alternatively, to get a specific version:
   - Remove the current directory: `rm -rf deps/nmap`
   - Clone the specific version: `git clone --branch <version> https://github.com/nmap/nmap.git deps/nmap`
4. Test the build process

### Build Script Integration

The build scripts have been modified to use local copies of dependencies:

- OpenSSL: `cp -r /build/deps/openssl-${OPENSSL_VERSION} .` instead of downloading from the internet
- Nmap: `cp -r /build/deps/nmap .` instead of cloning from GitHub during build time

This ensures all builds use the exact same source code versions and can be performed offline.