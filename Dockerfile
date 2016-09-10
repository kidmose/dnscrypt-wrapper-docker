FROM debian:8
MAINTAINER dnscrypt.io

ENV BUILD_DEPENDENCIES \
    autoconf \
    bzip2 \
    curl \
    gcc \
    make

RUN set -x && \
    apt-get update && \
    apt-get install -y $BUILD_DEPENDENCIES # --no-install-recommends
    # TODO: don't install recomended packages, rather specify in BUILD_DEPENDENCIES

ENV LIBSODIUM_VERSION 1.0.11
ENV LIBSODIUM_SHA256 71b786a96dd03693672b0ca3eb77f4fb08430df307051c0d45df5353d22bc4be
ENV LIBSODIUM_DOWNLOAD_URL https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VERSION}.tar.gz

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    curl -sSL $LIBSODIUM_DOWNLOAD_URL -o libsodium.tar.gz && \
    echo "${LIBSODIUM_SHA256} *libsodium.tar.gz" | sha256sum -c - && \
    tar xzf libsodium.tar.gz && \
    rm -f libsodium.tar.gz && \
    cd libsodium-${LIBSODIUM_VERSION} && \
    ./configure --disable-dependency-tracking --enable-minimal --prefix=/opt/libsodium && \
    make check && make install && \
    echo /opt/libsodium/lib > /etc/ld.so.conf.d/libsodium.conf && ldconfig && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV DNSCRYPT_WRAPPER_VERSION 0.2
ENV DNSCRYPT_WRAPPER_SHA256 d26f9d6329653b71bed5978885385b45f16596021f219f46e49da60d5813054e
ENV DNSCRYPT_WRAPPER_DOWNLOAD_URL https://github.com/Cofyc/dnscrypt-wrapper/releases/download/v${DNSCRYPT_WRAPPER_VERSION}/dnscrypt-wrapper-v${DNSCRYPT_WRAPPER_VERSION}.tar.bz2
ENV DNSCRYPT_WRAPPER_USER dnscrypt-wrapper
ENV DNSCRYPT_WRAPPER_KEYS /opt/dnscrypt-wrapper/etc/keys

RUN set -x && \
    apt-get update && \
    apt-get install -y \
    libevent-2.0 \
    libevent-dev \
    --no-install-recommends && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    curl -sSL $DNSCRYPT_WRAPPER_DOWNLOAD_URL -o dnscrypt-wrapper.tar.bz2 && \
    echo "${DNSCRYPT_WRAPPER_SHA256} *dnscrypt-wrapper.tar.bz2" | sha256sum -c - && \
    tar xjf dnscrypt-wrapper.tar.bz2 && \
    cd dnscrypt-wrapper-v${DNSCRYPT_WRAPPER_VERSION} && \
    make configure && \
    ./configure --prefix=/opt/dnscrypt-wrapper --with-sodium=/opt/libsodium && \
    make install && \
    mkdir -p /opt/dnscrypt-wrapper/empty && \
    groupadd ${DNSCRYPT_WRAPPER_USER} && \
    useradd -g ${DNSCRYPT_WRAPPER_USER} -s /bin/false -d /opt/dnscrypt-wrapper/empty ${DNSCRYPT_WRAPPER_USER} && \
    mkdir -p ${DNSCRYPT_WRAPPER_KEYS} && \
    apt-get purge -y --auto-remove libevent-dev && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -x && \
    apt-get purge -y --auto-remove $BUILD_DEPENDENCIES && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER ${DNSCRYPT_WRAPPER_USER}

ENTRYPOINT ["/opt/dnscrypt-wrapper/sbin/dnscrypt-wrapper"]

CMD ["--help"]
