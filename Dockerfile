FROM ubuntu:20.04


RUN rm -rf /var/lib/apt/lists/*

RUN apt update && apt install aptitude -y

ENV TZ=Asia/Calcutta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update && apt clean && apt upgrade -y
RUN apt install -y tzdata

RUN aptitude install libmicrohttpd-dev libjansson-dev \
    libssl-dev libsofia-sip-ua-dev libglib2.0-dev \
    libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev \
    libconfig-dev pkg-config gengetopt libtool automake -y

RUN apt install git-all -y

RUN  apt-cache madison python3  python3-pip 
RUN apt install python3 python3-pip -y
RUN pip3 install meson ninja

RUN git clone https://gitlab.freedesktop.org/libnice/libnice && cd libnice && \
    meson --prefix=/usr build && ninja -C build &&  ninja -C build install

RUN apt install wget
RUN SRTP="2.4.0" && apt-get remove -y libsrtp0-dev && wget https://github.com/cisco/libsrtp/archive/v$SRTP.tar.gz && \
    tar xfv v$SRTP.tar.gz && \
    cd libsrtp-$SRTP && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library && make install


# # Boringssl build section
RUN apt-get -y update && apt-get install -y --no-install-recommends \
    g++ \
    gcc \
    curl \
    libc6-dev \
    make \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*
ENV GOLANG_VERSION 1.7.5
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 2e4dd6c44f0693bef4e7b46cc701513d74c3cc44f2419bf519d7868b12931ac3
RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
    && echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"


RUN apt-get update && apt install cmake -y

RUN git clone https://boringssl.googlesource.com/boringssl && \
    cd boringssl  && \
    # Don't barf on errors
    sed -i s/" -Werror"//g CMakeLists.txt  && \
    # Build
    mkdir -p build && \
    cd build && \
    cmake -DCMAKE_CXX_FLAGS="-lrt" .. && \
    make && \
    cd .. && \
    # Install
    mkdir -p /opt/boringssl && \
    cp -R include /opt/boringssl/ && \
    mkdir -p /opt/boringssl/lib  && \
    cp build/ssl/libssl.a /opt/boringssl/lib/ && \
    cp build/crypto/libcrypto.a /opt/boringssl/lib/

RUN git clone https://github.com/sctplab/usrsctp && \
    cd usrsctp && \
    ./bootstrap && \
    ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 && \
    make &&  make install


RUN git clone https://libwebsockets.org/repo/libwebsockets && \
    cd libwebsockets && \
    # If you want the stable version of libwebsockets, uncomment the next line
    # git checkout v3.2-stable
    mkdir build && \
    cd build && \
    # See https://github.com/meetecho/janus-gateway/issues/732 re: LWS_MAX_SMP
    # See https://github.com/meetecho/janus-gateway/issues/2476 re: LWS_WITHOUT_EXTENSIONS
    cmake -DLWS_MAX_SMP=1 -DLWS_WITHOUT_EXTENSIONS=0 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && \
    make &&  make install

RUN git clone https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway && \
    sh autogen.sh && \
    ./configure   --enable-data-channels \
    --enable-boringssl \
    --disable-rabbitmq \
    --disable-mqtt \
    --disable-unix-sockets \
    --enable-dtls-settimeout \
    #     --enable-plugin-echotest \
    #     --enable-plugin-recordplay \
    #     --enable-plugin-sip \
    --enable-plugin-videocall \
    --enable-plugin-voicemail \
    --enable-plugin-textroom \
    --enable-rest \
    # s--enable-turn-rest-api \
    #     --enable-plugin-audiobridge \
    #     --enable-plugin-nosip \
    --enable-all-handlers && \
    make && make install && make configs    

RUN apt apt-get clean &&  apt-get autoremove  -y

CMD janus  -S "stun.voip.eutelia.it:3478" --full-trickle
EXPOSE 80 7088 7089 8088 8188 8089
EXPOSE 10000-10200/udp
EXPOSE 40000-65535/udp
