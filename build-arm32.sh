#!/bin/bash

set -e
set -o pipefail
set -x

function build_nmap() {
    cd /build

    # Use local nmap copy instead of cloning
    cp -r /build/deps/nmap .
    cd nmap

    # Configure (without OpenSSL to avoid cross-compilation issues)
    CC='arm-linux-musleabihf-gcc -static -fPIC' \
        CXX='arm-linux-musleabihf-g++ -static -static-libstdc++ -fPIC' \
        LD=arm-linux-musleabihf-ld \
        ./configure \
            --host=arm-linux-musleabihf \
            --without-ndiff \
            --without-zenmap \
            --without-nmap-update \
            --without-openssl \
            --with-pcap=linux

    # Don't build the libpcap.so file
    sed -i -e 's/shared\: /shared\: #/' libpcap/Makefile || true
    sed -i -e 's/shared\: /shared\: #/' libz/Makefile || true

    # Build
    make -j4
    arm-linux-musleabihf-strip nmap ncat/ncat nping/nping
}

function doit() {
    build_nmap

    # Copy to output
    if [ -d /output ]
    then
        OUT_DIR=/output/linux/armv7l
        mkdir -p $OUT_DIR && mkdir -p $OUT_DIR/scripts && mkdir -p $OUT_DIR/nselib
        cp /build/nmap/nmap $OUT_DIR/
        cp /build/nmap/ncat/ncat $OUT_DIR/
        cp /build/nmap/nping/nping $OUT_DIR/
        cp /build/nmap/scripts/* $OUT_DIR/scripts/
        cp -R /build/nmap/nselib/* $OUT_DIR/nselib/
        echo "** Finished ARM32 build **"
    else
        echo "** /output does not exist **"
    fi
}

doit