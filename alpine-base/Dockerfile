
FROM alpine as build

ENV NGINX_VERSION 1.22.1

ENV MODSEC_VERSION v3.0.9
ENV MOD_NGX_VERSION v1.0.3

ENV OWASP_VERSION v3.3.4

ENV UPSTREAM_CHECK_VERSION v0.4.0
ENV VTS_VERSION v0.2.1

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN apk update && apk add  bash bash-completion nano

RUN apk add build-base pcre-dev openssl-dev zlib-dev wget git unzip flex bison uthash uthash-dev libsodium libsodium-dev libxml2-dev lmdb-dev libtool autoconf automake autoconf linux-headers

# 下载并解压nginx

WORKDIR /opt

RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar -zxvf nginx-${NGINX_VERSION}.tar.gz
RUN mv nginx-${NGINX_VERSION}/ nginx/

# headers-more-nginx-module 和 ngx_hidden_signature_patch
RUN git clone -b master https://github.com/openresty/headers-more-nginx-module.git headers-more-nginx-module
RUN git clone -b master https://github.com/torden/ngx_hidden_signature_patch.git ngx_hidden_signature_patch

# ModSecurity和连接件
RUN git clone -b ${MODSEC_VERSION} --depth 1 https://github.com/SpiderLabs/ModSecurity
RUN git clone -b ${MOD_NGX_VERSION} https://github.com/SpiderLabs/ModSecurity-nginx.git

# /coreruleset是规则，直接git到/usr/local/coreruleset/
RUN git clone -b ${OWASP_VERSION} --depth 1 https://github.com/coreruleset/coreruleset.git /usr/local/coreruleset/

# nginx_upstream_check_module，这个需要打补丁的
RUN git clone -b ${UPSTREAM_CHECK_VERSION} https://github.com/yaoweibin/nginx_upstream_check_module.git

# 获取 nginx-module-vts
RUN git clone -b ${VTS_VERSION} https://github.com/vozlt/nginx-module-vts.git

# nginx-sticky-module-ng，这个需要打补丁的
RUN git clone https://github.com/ishushkin/nginx-sticky-module-ng.git

# 
WORKDIR /opt/ModSecurity
RUN git submodule update --init --recursive

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

RUN addgroup --gid 404 --system nginx && \
    adduser --uid 404 --system --disabled-password --no-create-home --home /webroot --ingroup nginx nginx

RUN mkdir /app && mkdir /config && mkdir /log && mkdir /webroot  

# 下载并解压nginx

# nginx_upstream_check_module给nginx-sticky-module-ng 打补丁
WORKDIR /opt/nginx-sticky-module-ng
RUN patch -p0 < ../nginx_upstream_check_module/nginx-sticky-module.patch

# nginx_upstream_check_module给nginx打补丁
WORKDIR /opt/nginx
RUN patch -p1 < ../nginx_upstream_check_module/check_1.20.1+.patch

# ngx_hidden_signature_patch给nginx打补丁
WORKDIR /opt/nginx
RUN patch -p0 < ../ngx_hidden_signature_patch/nginx-1.22.x-1.23.x-ngx_http_header_filter_module.c.patch  && \
    patch -p0 < ../ngx_hidden_signature_patch/nginx-1.14.x-1.23.x-ngx_http_special_response.c.patch  && \
    patch -p0 < ../ngx_hidden_signature_patch/nginx-1.14.x-1.23.x-ngx_http_v2_filter_module.c.patch


# 编译ModSecurity
WORKDIR /opt/ModSecurity
RUN ./build.sh 
RUN ./configure --with-lmdb
RUN make -j$(nproc)
RUN make install

# 编译并安装动态版本nginx
WORKDIR /opt/nginx
RUN ./configure --prefix=/app \
                --modules-path=/app/modules \
                --sbin-path=/app/nginx \
                \
                --user=nginx \
			    --group=nginx \
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
                --add-module=/opt/headers-more-nginx-module  \
                --add-module=/opt/ModSecurity-nginx     \
                --add-module=/opt/nginx-module-vts             \
                --add-module=/opt/nginx-sticky-module-ng       \
                --add-module=/opt/nginx_upstream_check_module  \
                \
                --build="alpine-$(cat /etc/alpine-release) $(date +%Y/%m/%d\ %H:%M)"
RUN make
RUN make install

# 删除无用的文件
RUN rm -rf /usr/local/modsecurity/lib/libmodsecurity.a 	/usr/local/modsecurity/lib/libmodsecurity.la

# 复制配置文件
COPY config/ /config/
RUN cp /opt/ModSecurity/modsecurity.conf-recommended /config/modsec/modsecurity.conf
RUN cp /opt/ModSecurity/unicode.mapping /config/modsec/unicode.mapping
RUN sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /config/modsec/modsecurity.conf
RUN mv /usr/local/coreruleset/crs-setup.conf.example /usr/local/coreruleset/crs-setup.conf

# 将/config的配置文件打包
WORKDIR /config
RUN tar -czvf /tmp/config.tar.gz *

# 将nginx程序和依赖打包
WORKDIR /
RUN tar -czvf /tmp/nginx.tar.gz -h /app $(ldd /app/nginx | grep "=> /" | awk '{print $3}' | sort -u)

FROM alpine  as production

LABEL maintainer="liantian-cn"

# 安装必要的包 bash和nano
RUN apk update &&  apk add --no-cache bash nano bash-completion && rm -vrf /var/cache/apk/*

# 新建nginx用户
RUN addgroup --gid 404 --system nginx && \
    adduser --uid 404 --system --disabled-password --no-create-home --home /webroot --ingroup nginx nginx

# 从build容器复制config.tar.gz和nginx.tar.gz

COPY --from=build /tmp/config.tar.gz /config.tar.gz
COPY --from=build /tmp/nginx.tar.gz /nginx.tar.gz

# 从build容器复制modsecurity和coreruleset
# COPY --from=build /usr/local/modsecurity /usr/local/modsecurity
COPY --from=build /usr/local/coreruleset /usr/local/coreruleset
COPY REQUEST-910-IP-REPUTATION-remove-geo.conf /usr/local/coreruleset/rules/

# 将nginx解压

RUN tar -xzvf  /nginx.tar.gz -C / && \
    rm /nginx.tar.gz

# 创建安装目录
RUN mkdir -p /webroot && mkdir /log && mkdir /config

VOLUME ["/log", "/config", "/webroot"]

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

WORKDIR /webroot

EXPOSE 80 443

STOPSIGNAL SIGQUIT

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD ["/app/nginx", "-g", "daemon off;"]