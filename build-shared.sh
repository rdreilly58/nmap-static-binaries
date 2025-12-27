#!/bin/bash

set -e
set -o pipefail
set -x

OPENSSL_VERSION=1.1.1w

# If a cross-host is specified, set cross toolchain names
# CROSS_HOST may be: aarch64-linux-gnu or arm-linux-gnueabihf
if [ -n "${CROSS_HOST:-}" ]; then
    case "${CROSS_HOST}" in
        aarch64-*|*aarch64*)
            CROSS_CC=aarch64-linux-gnu-gcc
            CROSS_CXX=aarch64-linux-gnu-g++
            CROSS_AR=aarch64-linux-gnu-ar
            CROSS_STRIP=aarch64-linux-gnu-strip
            CROSS_RANLIB=aarch64-linux-gnu-ranlib
            ;;
        arm-linux-gnueabihf|armhf|armv7l|*arm*)
            CROSS_CC=arm-linux-gnueabihf-gcc
            CROSS_CXX=arm-linux-gnueabihf-g++
            CROSS_AR=arm-linux-gnueabihf-ar
            CROSS_STRIP=arm-linux-gnueabihf-strip
            CROSS_RANLIB=arm-linux-gnueabihf-ranlib
            ;;
        *)
            echo "Unknown CROSS_HOST=${CROSS_HOST}, proceeding without cross compiler mapping"
            ;;
    esac
fi

function build_openssl_shared() {
    cd /build

    # Use local OpenSSL copy instead of downloading
    cp -r /build/deps/openssl-${OPENSSL_VERSION} openssl-shared-${OPENSSL_VERSION}
    cd openssl-shared-${OPENSSL_VERSION}

    # Configure: pick the right Configure target for OpenSSL based on arch
    ARCH="${TARGET_ARCH:-$(uname -m)}"
    OPENSSL_CONFIG_TARGET="linux-x86_64"
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        OPENSSL_CONFIG_TARGET="linux-aarch64"
    fi
    # ARM32 targets: armv7l, armv7, arm
    if [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "armv7" ] || [ "$ARCH" = "arm" ]; then
        OPENSSL_CONFIG_TARGET="linux-armv4"
    fi
    
    # Configure for shared libraries (remove no-shared and -static flags)
    if [ -n "${CROSS_CC:-}" ]; then
        echo "Using cross compiler ${CROSS_CC} for shared OpenSSL"
        CC="${CROSS_CC}" ./Configure shared ${OPENSSL_CONFIG_TARGET}
    else
        CC='gcc' ./Configure shared ${OPENSSL_CONFIG_TARGET}
    fi

    # Build shared libraries
    make
    echo "** Finished building shared OpenSSL"
}

function build_nmap_shared() {
    cd /build

    # Use local nmap copy instead of cloning
    cp -r /build/deps/nmap nmap-shared
    cd nmap-shared

    # Configure for dynamic linking (remove -static flags)
    if [ -n "${CROSS_CC:-}" ]; then
        CC="${CROSS_CC} -fPIC"
        CXX="${CROSS_CXX} -fPIC"
    else
        CC='gcc -fPIC'
        CXX='g++ -fPIC'
    fi
    \
        LD=ld \
        LDFLAGS="-L/build/openssl-shared-${OPENSSL_VERSION}"   \
        ./configure \
            --without-ndiff \
            --without-zenmap \
            --without-nmap-update \
            --with-pcap=linux \
            --with-openssl=/build/openssl-shared-${OPENSSL_VERSION} \
            $( [ -n "${CROSS_HOST:-}" ] && printf "--host=%s" "$CROSS_HOST" || printf "" )

    # Allow building shared libraries (don't disable them)
    # sed -i -e 's/shared\: /shared\: #/' libpcap/Makefile
    # sed -i -e 's/shared\: /shared\: #/' libz/Makefile

    # Build dynamically linked versions
    make -j4
    strip nmap ncat/ncat nping/nping
}

function doit() {
    build_openssl_shared
    build_nmap_shared

    # Copy to output with -shared suffix
    if [ -d /output ]
    then
        OUT_DIR=/output/`uname | tr 'A-Z' 'a-z'`/`uname -m`-shared
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
        
        echo "** Finished shared build **"
    else
        echo "** /output does not exist **"
    fi
}

doit