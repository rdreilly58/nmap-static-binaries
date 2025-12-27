#!/bin/bash

set -e
set -o pipefail
set -x

function build_nmap_shared() {
    cd /build

    # Use local nmap copy instead of cloning
    cp -r /build/deps/nmap nmap-shared
    cd nmap-shared

    # Configure for dynamic linking (without OpenSSL to avoid cross-compilation issues)
    CC='arm-linux-musleabihf-gcc -fPIC' \
        CXX='arm-linux-musleabihf-g++ -fPIC' \
        LD=arm-linux-musleabihf-ld \
        ./configure \
            --host=arm-linux-musleabihf \
            --without-ndiff \
            --without-zenmap \
            --without-nmap-update \
            --without-openssl \
            --with-pcap=linux

    # Allow building shared libraries
    # Don't disable shared library building

    # Build dynamically linked versions
    make -j4
    arm-linux-musleabihf-strip nmap ncat/ncat nping/nping
}

function doit() {
    build_nmap_shared

    # Copy to output
    if [ -d /output ]
    then
        OUT_DIR=/output/linux/armv7l-shared
        mkdir -p $OUT_DIR && mkdir -p $OUT_DIR/scripts && mkdir -p $OUT_DIR/nselib && mkdir -p $OUT_DIR/lib
        
        # Copy binaries
        cp /build/nmap-shared/nmap $OUT_DIR/
        cp /build/nmap-shared/ncat/ncat $OUT_DIR/
        cp /build/nmap-shared/nping/nping $OUT_DIR/
        
        # Copy scripts and libraries
        cp /build/nmap-shared/scripts/* $OUT_DIR/scripts/
        cp -R /build/nmap-shared/nselib/* $OUT_DIR/nselib/
        
        # Copy any shared libraries that were built
        find /build/nmap-shared -name "*.so*" -exec cp {} $OUT_DIR/lib/ \; 2>/dev/null || true
        
        echo "** Finished ARM32 shared build **"
    else
        echo "** /output does not exist **"
    fi
}

doit