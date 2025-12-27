#!/bin/bash

set -e

echo "Building nmap static AND shared binaries for multiple architectures..."

# Build x86_64 shared
echo "=== Building x86_64 shared ==="
docker build --platform linux/amd64 -f Dockerfile.x86_64-shared -t nmap-shared-x86_64 .
docker run --platform linux/amd64 -v $(pwd):/output nmap-shared-x86_64

# Build ARM64 shared
echo "=== Building ARM64 shared ==="
docker build -f Dockerfile.arm64-shared -t nmap-shared-arm64 .
docker run -v $(pwd):/output nmap-shared-arm64

# Build ARM32 shared
echo "=== Building ARM32 shared ==="
docker build -f Dockerfile.arm32-shared -t nmap-shared-arm32 .
docker run -v $(pwd):/output nmap-shared-arm32

echo "=== Shared Build Summary ==="
echo "Built shared binaries for:"
ls -la linux/*-shared/nmap 2>/dev/null || echo "No shared binaries found"

echo "=== Shared File sizes ==="
find linux -name "*-shared" -type d -exec echo "=== {} ===" \; -exec ls -lh {}/nmap {}/ncat {}/nping \; 2>/dev/null || echo "No shared binaries found"

echo "=== Shared Libraries ==="
find linux -name "*-shared" -type d -exec echo "=== {} ===" \; -exec ls -lh {}/lib/ \; 2>/dev/null || echo "No shared libraries found"

echo "=== Verification ==="
for arch_dir in linux/*-shared/; do
    if [ -f "${arch_dir}nmap" ]; then
        echo "Architecture: $(basename $arch_dir)"
        file "${arch_dir}nmap"
        echo "Dependencies:"
        ldd "${arch_dir}nmap" 2>/dev/null || echo "  (static or cross-compiled binary)"
        echo ""
    fi
done

echo "Shared build complete!"