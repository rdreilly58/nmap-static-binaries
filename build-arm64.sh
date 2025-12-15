#!/bin/bash

set -e
set -o pipefail
set -x

OPENSSL_VERSION=1.1.1w

function build_openssl() {
    cd /build

    # Use local OpenSSL copy instead of downloading
    cp -r /build/deps/openssl-${OPENSSL_VERSION} .
    cd openssl-${OPENSSL_VERSION}

    # Configure
    CC='aarch64-linux-musl-gcc -static' \
        AR='aarch64-linux-musl-ar' \
        RANLIB='aarch64-linux-musl-ranlib' \
        ./Configure no-shared linux-aarch64

    # Generate all configuration headers
    perl configdata.pm --dump
    make build_generated

    # Build only what we need (skip tests)
    make libcrypto.a libssl.a apps/openssl
    echo "** Finished building OpenSSL"
}

function build_nmap() {
    cd /build

    # Use local nmap copy instead of cloning
    cp -r /build/deps/nmap .
    cd nmap

    # Configure
    CC='aarch64-linux-musl-gcc -static -fPIC' \
        CXX='aarch64-linux-musl-g++ -static -static-libstdc++ -fPIC' \
        LD=aarch64-linux-musl-ld \
        LDFLAGS="-L/build/openssl-${OPENSSL_VERSION}"   \
        ./configure \
            --host=aarch64-linux-musl \
            --without-ndiff \
            --without-zenmap \
            --without-nmap-update \
            --with-pcap=linux \
            --with-openssl=/build/openssl-${OPENSSL_VERSION}

    # Don't build the libpcap.so file
    sed -i -e 's/shared\: /shared\: #/' libpcap/Makefile
    sed -i -e 's/shared\: /shared\: #/' libz/Makefile

    # Build
    make -j4
    aarch64-linux-musl-strip nmap ncat/ncat nping/nping
}

function doit() {
    build_openssl
    build_nmap

    # Copy to output
    if [ -d /output ]
    then
        OUT_DIR=/output/linux/aarch64
        mkdir -p $OUT_DIR && mkdir -p $OUT_DIR/scripts && mkdir -p $OUT_DIR/nselib
        cp /build/nmap/nmap $OUT_DIR/
        cp /build/nmap/ncat/ncat $OUT_DIR/
        cp /build/nmap/nping/nping $OUT_DIR/
        cp /build/nmap/scripts/* $OUT_DIR/scripts/
        cp -R /build/nmap/nselib/* $OUT_DIR/nselib/
        echo "** Finished ARM64 build **"
    else
        echo "** /output does not exist **"
    fi
}

doit