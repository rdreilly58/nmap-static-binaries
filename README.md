# nmap-static-binaries

Comprehensive nmap binary compilation for multiple architectures with both static and shared library versions.

## Overview

This repository provides Docker-based build systems to compile nmap binaries for multiple architectures:
- **x86_64** (Intel/AMD 64-bit)
- **ARM64** (aarch64) 
- **ARM32** (armv7l)

Each architecture supports two build types:
- **Static binaries**: Self-contained executables with no external dependencies
- **Shared library versions**: Dynamically linked binaries with accompanying .so files

## Quick Start

### Build All Static Binaries
```sh
./build-all.sh
```

### Build All Shared Library Versions  
```sh
./build-all-shared.sh
```

### Build Specific Architecture
```sh
# Static versions
./build-arm64.sh
./build-arm32.sh
docker build -f Dockerfile.x86_64 -t nmap-static-x86_64 .
docker run -v $(pwd):/output nmap-static-x86_64

# Shared versions
docker build -f Dockerfile.x86_64-shared -t nmap-shared-x86_64 .
docker run -v $(pwd):/output nmap-shared-x86_64
```

## Output Structure

After building, binaries are organized by architecture and type:

```
linux/
├── x86_64/              # Static x86_64 binaries
│   ├── nmap
│   ├── ncat  
│   ├── nping
│   ├── scripts/         # NSE scripts
│   └── nselib/          # Lua libraries
├── x86_64-shared/       # Shared x86_64 binaries
│   ├── nmap
│   ├── ncat
│   ├── nping
│   ├── lib/             # Shared libraries (.so files)
│   │   ├── libssl.so*
│   │   ├── libcrypto.so*
│   │   └── *.so*
│   ├── scripts/
│   └── nselib/
├── aarch64/             # Static ARM64 binaries
├── aarch64-shared/      # Shared ARM64 binaries
├── armv7l/              # Static ARM32 binaries
└── armv7l-shared/       # Shared ARM32 binaries
```

## Build Types Comparison

| Feature | Static Binaries | Shared Library Versions |
|---------|----------------|-------------------------|
| **Dependencies** | None (self-contained) | Requires .so files |
| **Binary Size** | Larger (~15-25MB) | Smaller (~2-5MB) |
| **Deployment** | Single file | Binary + lib/ directory |
| **Memory Usage** | Higher per process | Shared between processes |
| **Portability** | Maximum | Requires compatible libraries |
| **Use Case** | Penetration testing, isolated environments | Standard deployments, package managers |

## Architecture-Specific Building

### x86_64 (Intel/AMD 64-bit)

**Static:**
```sh
docker build -f Dockerfile.x86_64 -t nmap-static-x86_64 .
docker run -v $(pwd):/output nmap-static-x86_64
```

**Shared:**
```sh
docker build -f Dockerfile.x86_64-shared -t nmap-shared-x86_64 .
docker run -v $(pwd):/output nmap-shared-x86_64
```

### ARM64 (aarch64)

**Static:**
```sh
./build-arm64.sh
# OR
docker build -f Dockerfile.arm64 -t nmap-static-arm64 .
docker run -v $(pwd):/output nmap-static-arm64
```

**Shared:**
```sh
docker build -f Dockerfile.arm64-shared -t nmap-shared-arm64 .
docker run -v $(pwd):/output nmap-shared-arm64
```

### ARM32 (armv7l)

**Static:**
```sh
./build-arm32.sh
# OR
docker build -f Dockerfile.arm32 -t nmap-static-arm32 .
docker run -v $(pwd):/output nmap-static-arm32
```

**Shared:**
```sh
docker build -f Dockerfile.arm32-shared -t nmap-shared-arm32 .
docker run -v $(pwd):/output nmap-shared-arm32
```

## Cross-Compilation Support

The build system supports multiple cross-compilation strategies:

```sh
# Build everything (auto-detects best method)
./build-all.sh

# Cross-compile using Debian container with cross toolchains
./build-cross.sh

# Force cross-compile with specific target
docker run --rm -e CROSS_HOST=aarch64-linux-gnu -e TARGET_ARCH=aarch64 \
  -v $(pwd)/output:/output nmap-build-cross
```

## Dependencies

This repository includes local copies of all dependencies for reproducible, offline builds.

### Local Dependencies

Located in the `deps/` directory:

- **OpenSSL 1.1.1w**: SSL/TLS functionality
- **Nmap source**: Latest from GitHub (bleeding edge)

### Benefits

- ✅ **Reproducible builds**: Exact same source versions
- ✅ **Offline capability**: No internet required during build
- ✅ **Version control**: Dependencies tracked in repository
- ✅ **Faster builds**: No download time
- ✅ **Security**: No supply chain attack vectors

See `deps/README.md` for dependency management details.

## Usage Examples

### Penetration Testing (Static Binaries)

```sh
# Copy single static binary to target
scp linux/x86_64/nmap user@target:/tmp/
ssh user@target "/tmp/nmap -sS -O target_ip"
```

### Production Deployment (Shared Libraries)

```sh
# Deploy with shared libraries
rsync -av linux/x86_64-shared/ user@server:/opt/nmap/
ssh user@server "LD_LIBRARY_PATH=/opt/nmap/lib /opt/nmap/nmap -sV target"
```

### Container Deployment

```dockerfile
# Static binary in minimal container
FROM scratch
COPY linux/x86_64/nmap /nmap
ENTRYPOINT ["/nmap"]

# Shared library container
FROM alpine:latest
RUN apk add --no-cache libc6-compat
COPY linux/x86_64-shared/ /opt/nmap/
ENV LD_LIBRARY_PATH=/opt/nmap/lib
ENTRYPOINT ["/opt/nmap/nmap"]
```

## Scanning Scripts

The repository includes ready-to-use scanning scripts:

### scan.sh
Performs comprehensive scanning with three concurrent scan types:
```sh
./linux/x86_64/scan.sh 192.168.1.1
```

### scan-port.sh  
Detailed port-specific scanning with NSE scripts:
```sh
./linux/x86_64/scan-port.sh 192.168.1.1 80 "http*,banner,vuln"
```

### full-scan.sh
Complete network reconnaissance:
```sh
./linux/x86_64/full-scan.sh 192.168.1.1
```

## Binary Verification

Verify architecture and linking:

```sh
# Check architecture
file linux/x86_64/nmap
# Output: ELF 64-bit LSB executable, x86-64, statically linked

file linux/x86_64-shared/nmap  
# Output: ELF 64-bit LSB executable, x86-64, dynamically linked

# Check dependencies (shared only)
ldd linux/x86_64-shared/nmap
```

## Requirements

- **Docker**: For containerized builds
- **Docker Buildx**: For cross-platform builds (optional)
- **QEMU**: For emulation-based builds (optional)

## Troubleshooting

### Build Issues

1. **Docker space**: Ensure sufficient disk space (>10GB recommended)
2. **Memory**: ARM builds may require 4GB+ RAM
3. **Permissions**: Ensure Docker daemon access

### Runtime Issues

1. **Static binaries**: Should run on any Linux system
2. **Shared binaries**: Verify library compatibility with `ldd`
3. **Cross-architecture**: Use appropriate binary for target system

## Contributing

1. **Dependencies**: Update versions in `deps/README.md`
2. **Build scripts**: Test across all architectures
3. **Documentation**: Update README for new features

## Credits

- **Original**: Andrew-d's static-binaries project
- **Enhanced by**: Bob Reilly
- **Modifications**:
  - Added local dependency management
  - Multi-architecture support
  - Static + shared library builds
  - Comprehensive build automation
  - Updated to latest nmap (bleeding edge)
  - OpenSSL 1.1.1w integration

## License

This project maintains compatibility with nmap's licensing requirements. See individual component licenses for details.