FROM alpine


RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN apk update && apk add  bash bash-completion nano

RUN apk add build-base pcre-dev openssl-dev zlib-dev wget git unzip flex bison uthash uthash-dev libsodium libsodium-dev libxml2-dev lmdb-dev libtool autoconf automake autoconf linux-headers
