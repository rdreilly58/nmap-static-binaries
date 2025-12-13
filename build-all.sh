#!/bin/bash

set -e

echo "Building nmap static binaries for multiple architectures..."

# Build x86_64
echo "=== Building x86_64 ==="
docker build --platform linux/amd64 -f Dockerfile.x86_64 -t nmap-static-x86_64 .
docker run --platform linux/amd64 -v $(pwd):/output nmap-static-x86_64

# Build ARM64
echo "=== Building ARM64 ==="
docker build -f Dockerfile.arm64 -t nmap-static-arm64 .
docker run -v $(pwd):/output nmap-static-arm64

# Build ARM32
echo "=== Building ARM32 ==="
docker build -f Dockerfile.arm32 -t nmap-static-arm32 .
docker run -v $(pwd):/output nmap-static-arm32

echo "=== Build Summary ==="
echo "Built binaries for:"
ls -la linux/*/nmap 2>/dev/null || echo "No binaries found"

echo "=== File sizes ==="
find linux -name "nmap" -exec ls -lh {} \; 2>/dev/null || echo "No nmap binaries found"
find linux -name "ncat" -exec ls -lh {} \; 2>/dev/null || echo "No ncat binaries found"
find linux -name "nping" -exec ls -lh {} \; 2>/dev/null || echo "No nping binaries found"

echo "=== Verification ==="
for arch_dir in linux/*/; do
    if [ -f "${arch_dir}nmap" ]; then
        echo "Architecture: $(basename $arch_dir)"
        file "${arch_dir}nmap"
        echo ""
    fi
done

echo "Build complete!"