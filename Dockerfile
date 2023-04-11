FROM alpine AS build


ENV NGINX_VERSION 1.22.1


RUN apk update && \
    apk upgrade && \
    apk add --no-cache bash bash-doc bash-completion nano build-base pcre-dev openssl-dev zlib-dev wget git unzip flex bison uthash uthash-dev libsodium libsodium-dev



RUN mkdir /builder

# 下载并解压nginx

RUN cd /builder && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN cd /builder && tar -zxvf nginx-${NGINX_VERSION}.tar.gz


# 获取 headers-more-nginx-module

RUN cd /builder && git clone https://github.com/openresty/headers-more-nginx-module.git headers-more-nginx-module

# 获取 nginx_upstream_check_module 并打补丁

RUN cd /builder && git clone https://github.com/yaoweibin/nginx_upstream_check_module.git nginx_upstream_check_module
RUN cd /builder/nginx-${NGINX_VERSION} && patch -p1 < /builder/nginx_upstream_check_module/check_1.20.1+.patch


# 获取 nginx-module-vts

RUN cd /builder && git clone https://github.com/vozlt/nginx-module-vts.git nginx-module-vts


# 获取 nginx-sticky-module-ng 并打补丁

RUN cd /builder && git clone https://github.com/ishushkin/nginx-sticky-module-ng.git nginx-sticky-module-ng
RUN cd /builder/nginx-sticky-module-ng && patch -p0 < /builder/nginx_upstream_check_module/nginx-sticky-module.patch


# 获取 ngx_hidden_signature_patch 并打补丁

RUN cd /builder && git clone https://github.com/torden/ngx_hidden_signature_patch.git ngx_hidden_signature_patch
RUN cd /builder/nginx-${NGINX_VERSION} && \
    patch -p0 < /builder/ngx_hidden_signature_patch/nginx-1.22.x-1.23.x-ngx_http_header_filter_module.c.patch && \
    patch -p0 < /builder/ngx_hidden_signature_patch/nginx-1.14.x-1.23.x-ngx_http_special_response.c.patch && \
    patch -p0 < /builder/ngx_hidden_signature_patch/nginx-1.14.x-1.23.x-ngx_http_v2_filter_module.c.patch


# 获取naxsi 

RUN cd /builder && wget -O naxsi.zip https://github.com/wargio/naxsi/releases/download/1.4/naxsi-1.4-src-with-deps.zip
RUN cd /builder && unzip naxsi.zip -d naxsi





# 构建基本目录

RUN  mkdir /app && mkdir /config && mkdir /log


# 编译并安装静态版本nginx，生成文件 /usr/local/nginx/sbin/nginx
RUN cd /builder/nginx-${NGINX_VERSION} && \
    \
    ./configure --with-http_ssl_module          \
                --with-http_stub_status_module  \
                --with-http_secure_link_module  \
                --with-pcre                     \
                --with-http_gzip_static_module  \
                --with-http_realip_module       \
                --with-http_sub_module          \
                --with-http_v2_module           \
                --add-module=/builder/headers-more-nginx-module    \
                --add-module=/builder/naxsi/naxsi_src              \
                --add-module=/builder/nginx-module-vts             \
                --add-module=/builder/nginx-sticky-module-ng       \
                --add-module=/builder/nginx_upstream_check_module  \
    && \
    make  && \
    make install

# 编译并安装动态版本nginx

RUN cd /builder/nginx-${NGINX_VERSION} && \
    \
    ./configure --prefix=/app \
                --modules-path=/app/modules \
                --sbin-path=/app/nginx \
                \
                --conf-path=/config/nginx.conf  \
                --http-log-path=/log/access.log \
                --error-log-path=/log/error.log \
                --pid-path=/log/nginx.pid       \
                --lock-path=/log/nginx.lock     \
                \
                --http-client-body-temp-path=/tmp/nginx_client_body_temp    \
                --http-proxy-temp-path=/tmp/nginx_proxy_temp                \
                --http-fastcgi-temp-path=/tmp/nginx_fastcgi_temp            \
                --http-uwsgi-temp-path=/tmp/nginx_uwsgi_temp                \
                --http-scgi-temp-path=/tmp/nginx_scgi_temp                  \
                \
                --with-http_ssl_module          \
                --with-http_stub_status_module  \
                --with-http_secure_link_module  \
                --with-pcre                     \
                --with-http_gzip_static_module  \
                --with-http_realip_module       \
                --with-http_sub_module          \
                --with-http_v2_module           \
                \
                --without-http_memcached_module \
                --without-http_scgi_module      \
                --without-http_ssi_module       \
                --without-http_grpc_module      \
                \
                --with-mail=dynamic     \
                --with-mail_ssl_module  \
                \
                --with-stream=dynamic               \
                --with-stream_ssl_module            \
                --with-stream_ssl_preread_module    \
                --with-stream_realip_module         \
                \
                --with-compat \
                --add-dynamic-module=/builder/headers-more-nginx-module     \
                --add-dynamic-module=/builder/naxsi/naxsi_src               \
                --add-dynamic-module=/builder/nginx-module-vts              \
                --add-dynamic-module=/builder/nginx-sticky-module-ng        \
                --add-dynamic-module=/builder/nginx_upstream_check_module   \
                \
                --build=alpine-$(cat /etc/alpine-release)-$(date +%Y%m%d%H%M%S)  && \
    \
    make  && \
    make install

# 复制一些插件的设置文件到/config,并将/config的配置文件打包
COPY nginx.conf /config/nginx.conf
RUN cp -r /builder/naxsi/naxsi_rules/ /config/
RUN cd /config && tar -czvf /tmp/config.tar.gz *

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

# 将nginx程序和依赖打包

RUN cd / && tar -czvf /tmp/nginx.tar.gz -h /app /docker-entrypoint.sh $(ldd /usr/local/nginx/sbin/nginx | grep "=> /" | awk '{print $3}' | sort -u)


FROM alpine

# 安装必要的包 bash和nano
RUN apk update && apk upgrade && apk add --no-cache bash nano && rm -vrf /var/cache/apk/*

# 从主容器复制config.tar.gz和nginx.tar.gz

COPY --from=build /tmp/config.tar.gz /origin_config.tar.gz
COPY --from=build /tmp/nginx.tar.gz /nginx.tar.gz

# 将nginx解压

RUN tar -xzvf  /nginx.tar.gz -C / && \
    rm /nginx.tar.gz

# 创建安装目录
RUN mkdir -p /data/static && mkdir -p /data/static && mkdir /log && mkdir /config

VOLUME ["/log", "/config", "/data/static", "/data/media"]

EXPOSE 80 443

STOPSIGNAL SIGQUIT

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD ["/app/nginx", "-g", "daemon off;"]