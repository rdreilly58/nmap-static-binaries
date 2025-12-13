#!/bin/bash

set -e
set -o pipefail
set -x

OPENSSL_VERSION=1.1.1w

function build_openssl() {
    cd /build

    # Download
    curl -LOk https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    tar zxvf openssl-${OPENSSL_VERSION}.tar.gz
    cd openssl-${OPENSSL_VERSION}

    # Configure
    CC='gcc -static' ./Configure no-shared linux-x86_64

    # Generate all configuration headers
    perl configdata.pm --dump
    make build_generated

    # Build only what we need (skip tests)
    make libcrypto.a libssl.a apps/openssl
    echo "** Finished building OpenSSL"
}

function build_nmap() {
    cd /build

    # Download
    git clone https://github.com/nmap/nmap.git
    cd nmap

    # Configure
    CC='gcc -static -fPIC' \
        CXX='g++ -static -static-libstdc++ -fPIC' \
        LD=ld \
        LDFLAGS="-L/build/openssl-${OPENSSL_VERSION}"   \
        ./configure \
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
    strip nmap ncat/ncat nping/nping
}

function doit() {
    build_openssl
    build_nmap

    # Copy to output
    if [ -d /output ]
    then
        OUT_DIR=/output/linux/x86_64
        mkdir -p $OUT_DIR && mkdir -p $OUT_DIR/scripts && mkdir -p $OUT_DIR/nselib
        cp /build/nmap/nmap $OUT_DIR/
        cp /build/nmap/ncat/ncat $OUT_DIR/
        cp /build/nmap/nping/nping $OUT_DIR/
        cp /build/nmap/scripts/* $OUT_DIR/scripts/
        cp -R /build/nmap/nselib/* $OUT_DIR/nselib/
        echo "** Finished x86_64 build **"
    else
        echo "** /output does not exist **"
    fi
}

doit