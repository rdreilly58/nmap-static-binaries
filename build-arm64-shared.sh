#!/bin/bash

set -e
set -o pipefail
set -x

OPENSSL_VERSION=1.1.1w

function build_openssl_shared() {
    cd /build

    # Use local OpenSSL copy instead of downloading
    cp -r /build/deps/openssl-${OPENSSL_VERSION} openssl-shared-${OPENSSL_VERSION}
    cd openssl-shared-${OPENSSL_VERSION}

    # Configure for shared libraries
    CC='aarch64-linux-musl-gcc' \
        AR='aarch64-linux-musl-ar' \
        RANLIB='aarch64-linux-musl-ranlib' \
        ./Configure shared linux-aarch64

    # Generate all configuration headers
    perl configdata.pm --dump
    make build_generated

    # Build shared libraries
    make libcrypto.so libssl.so apps/openssl
    echo "** Finished building shared OpenSSL"
}

function build_nmap_shared() {
    cd /build

    # Use local nmap copy instead of cloning
    cp -r /build/deps/nmap nmap-shared
    cd nmap-shared

    # Configure for dynamic linking
    CC='aarch64-linux-musl-gcc -fPIC' \
        CXX='aarch64-linux-musl-g++ -fPIC' \
        LD=aarch64-linux-musl-ld \
        LDFLAGS="-L/build/openssl-shared-${OPENSSL_VERSION}"   \
        ./configure \
            --host=aarch64-linux-musl \
            --without-ndiff \
            --without-zenmap \
            --without-nmap-update \
            --with-pcap=linux \
            --with-openssl=/build/openssl-shared-${OPENSSL_VERSION}

    # Allow building shared libraries
    # Don't disable shared library building

    # Build dynamically linked versions
    make -j4
    aarch64-linux-musl-strip nmap ncat/ncat nping/nping
}

function doit() {
    build_openssl_shared
    build_nmap_shared

    # Copy to output
    if [ -d /output ]
    then
        OUT_DIR=/output/linux/aarch64-shared
        mkdir -p $OUT_DIR && mkdir -p $OUT_DIR/scripts && mkdir -p $OUT_DIR/nselib && mkdir -p $OUT_DIR/lib
        
        # Copy binaries
        cp /build/nmap-shared/nmap $OUT_DIR/
        cp /build/nmap-shared/ncat/ncat $OUT_DIR/
        cp /build/nmap-shared/nping/nping $OUT_DIR/
        
        # Copy scripts and libraries
        cp /build/nmap-shared/scripts/* $OUT_DIR/scripts/
        cp -R /build/nmap-shared/nselib/* $OUT_DIR/nselib/
        
        # Copy shared OpenSSL libraries
        cp /build/openssl-shared-${OPENSSL_VERSION}/libssl.so* $OUT_DIR/lib/ 2>/dev/null || true
        cp /build/openssl-shared-${OPENSSL_VERSION}/libcrypto.so* $OUT_DIR/lib/ 2>/dev/null || true
        
        # Copy any other shared libraries that were built
        find /build/nmap-shared -name "*.so*" -exec cp {} $OUT_DIR/lib/ \; 2>/dev/null || true
        
        echo "** Finished ARM64 shared build **"
    else
        echo "** /output does not exist **"
    fi
}

doit