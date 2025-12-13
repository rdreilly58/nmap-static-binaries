#!/bin/bash

set -e
set -o pipefail
set -x


#NMAP_VERSION=7.91
# Nmap is bleeding edge from git
OPENSSL_VERSION=1.1.1q

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


function build_openssl() {
    cd /build

    # Download
    curl -LOk https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    tar zxvf openssl-${OPENSSL_VERSION}.tar.gz
    cd openssl-${OPENSSL_VERSION}

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
    if [ -n "${CROSS_CC:-}" ]; then
        echo "Using cross compiler ${CROSS_CC} for OpenSSL"
        CC="${CROSS_CC} -static" ./Configure no-shared ${OPENSSL_CONFIG_TARGET}
    else
        CC='gcc -static' ./Configure no-shared ${OPENSSL_CONFIG_TARGET}
    fi

    # Build
    make
    echo "** Finished building OpenSSL"
}

function build_nmap() {
    cd /build

    # Python is already installed in the container

    # Download
    #curl -LOk http://nmap.org/dist/nmap-${NMAP_VERSION}.tar.bz2
    #tar xjvf nmap-${NMAP_VERSION}.tar.bz2
    #cd nmap-${NMAP_VERSION}
	git clone https://github.com/nmap/nmap.git
	cd nmap

    # Configure (pick arch-aware flags if needed)
    if [ -n "${CROSS_CC:-}" ]; then
        CC="${CROSS_CC} -static -fPIC"
        CXX="${CROSS_CXX} -static -static-libstdc++ -fPIC"
    else
        CC='gcc -static -fPIC'
        CXX='g++ -static -static-libstdc++ -fPIC'
    fi
    \
        LD=ld \
        LDFLAGS="-L/build/openssl-${OPENSSL_VERSION}"   \
        ./configure \
            --without-ndiff \
            --without-zenmap \
            --without-nmap-update \
            --with-pcap=linux \
            --with-openssl=/build/openssl-${OPENSSL_VERSION} \
            $( [ -n "${CROSS_HOST:-}" ] && printf "--host=%s" "$CROSS_HOST" || printf "" )

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
        OUT_DIR=/output/`uname | tr 'A-Z' 'a-z'`/`uname -m`
        mkdir -p $OUT_DIR && mkdir -p $OUT_DIR/scripts && mkdir -p $OUT_DIR/nselib
        #cp /build/nmap-${NMAP_VERSION}/nmap $OUT_DIR/
        #cp /build/nmap-${NMAP_VERSION}/ncat/ncat $OUT_DIR/
        #cp /build/nmap-${NMAP_VERSION}/nping/nping $OUT_DIR/
		cp /build/nmap/nmap $OUT_DIR/
        cp /build/nmap/ncat/ncat $OUT_DIR/
        cp /build/nmap/nping/nping $OUT_DIR/
		cp /build/nmap/scripts/* $OUT_DIR/scripts/
		cp -R /build/nmap/nselib/* $OUT_DIR/nselib/
        echo "** Finished **"
    else
        echo "** /output does not exist **"
    fi
}

doit
