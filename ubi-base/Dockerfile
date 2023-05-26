# Use UBI-minimal as base image
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest as build

ENV NGINX_VERSION 1.22.1
ENV MODSEC_VERSION v3.0.9
ENV MOD_NGX_VERSION v1.0.3
ENV OWASP_VERSION v3.3.4
ENV UPSTREAM_CHECK_VERSION v0.4.0
ENV VTS_VERSION v0.2.1
ENV MAXMIND_LIB_VERSION 1.7.1
ENV GEO_DB_RELEASE 2023-05
# ENV PCRE2_VERSION 10.42
# ENV LIBXML2_VERSION v2.11.4

RUN microdnf install -y curl tar git bash bash-completion nano wget

# Set the work directory
WORKDIR /usr/src

# yum group info "Development Tools"
RUN microdnf install -y libtool autoconf automake gcc binutils make gettext pkg-config patch  bison flex gcc-c++ gdb glibc-devel
RUN microdnf install -y libxml2-devel libcurl-devel pcre2-devel openssl-devel

# Download and extract nginx source code
RUN curl -L http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar zx

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

# Install LMDB
RUN git clone https://github.com/LMDB/lmdb.git

# C library for the MaxMind DB
RUN git clone -b ${MAXMIND_LIB_VERSION} --recursive https://github.com/maxmind/libmaxminddb

# LIBXML2
# RUN git clone -b ${LIBXML2_VERSION} https://github.com/GNOME/libxml2.git

# PCRE2
# RUN curl -L https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz | tar zx
# RUN mv pcre2-${PCRE2_VERSION}/ pcre2/

# DBIP
RUN mkdir /opt/dbip
RUN wget -O - https://download.db-ip.com/free/dbip-city-lite-${GEO_DB_RELEASE}.mmdb.gz | gzip -d > /opt/dbip/city-lite.mmdb
RUN wget -O - https://download.db-ip.com/free/dbip-country-lite-${GEO_DB_RELEASE}.mmdb.gz | gzip -d > /opt/dbip/country-lite.mmdb

# ModSecurity获取子模块
WORKDIR /usr/src/ModSecurity
RUN git submodule update --init --recursive

# nginx_upstream_check_module给nginx-sticky-module-ng 打补丁
WORKDIR /usr/src/nginx-sticky-module-ng
RUN patch -p0 < ../nginx_upstream_check_module/nginx-sticky-module.patch

# nginx_upstream_check_module给nginx打补丁
WORKDIR /usr/src/nginx
RUN patch -p1 < ../nginx_upstream_check_module/check_1.20.1+.patch

# ngx_hidden_signature_patch给nginx打补丁
WORKDIR /usr/src/nginx
RUN patch -p0 < ../ngx_hidden_signature_patch/nginx-1.22.x-1.23.x-ngx_http_header_filter_module.c.patch  && \
    patch -p0 < ../ngx_hidden_signature_patch/nginx-1.14.x-1.23.x-ngx_http_special_response.c.patch  && \
    patch -p0 < ../ngx_hidden_signature_patch/nginx-1.14.x-1.23.x-ngx_http_v2_filter_module.c.patch

# lmdb
WORKDIR /usr/src/lmdb/libraries/liblmdb
RUN make -j$(nproc)
RUN make install

# libmaxminddb
WORKDIR /usr/src/libmaxminddb
RUN ./bootstrap
RUN ./configure 
RUN make -j$(nproc)
RUN make check
RUN make install

# # pcre2
# WORKDIR /usr/src/pcre2
# RUN ./configure --enable-jit
# RUN make -j$(nproc)
# RUN make check
# RUN make install


# 编译ModSecurity
WORKDIR /usr/src/ModSecurity
RUN ./build.sh 
RUN ./configure --disable-doxygen-doc --with-pcre2 --with-lmdb
RUN make -j$(nproc)
RUN make install

WORKDIR /usr/src/nginx
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
                --add-module=../headers-more-nginx-module  \
                --add-module=../ModSecurity-nginx     \
                --add-module=../nginx-module-vts             \
                --add-module=../nginx-sticky-module-ng       \
                --add-module=../nginx_upstream_check_module  \
                \
                --build="$(cat /etc/redhat-release) $(date +%Y/%m/%d\ %H:%M)"

RUN make
RUN make install

# 复制配置文件
COPY config/ /config/
RUN cp /usr/src/ModSecurity/modsecurity.conf-recommended /config/modsec/modsecurity.conf
RUN cp /usr/src/ModSecurity/unicode.mapping /config/modsec/unicode.mapping
RUN sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /config/modsec/modsecurity.conf
RUN mv /usr/local/coreruleset/crs-setup.conf.example /usr/local/coreruleset/crs-setup.conf

# 将/config的配置文件打包
WORKDIR /config
RUN tar -czvf /config.tar.gz *

WORKDIR /
RUN tar -czvf /nginx.tar.gz -h /app /opt/dbip/ $(ldd /app/nginx | grep "=> /" | awk '{print $3}' | sort -u)

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest as production

LABEL maintainer="liantian-cn"

# 安装必要的包 bash和nano
RUN microdnf install -y bash bash-completion nano  shadow-utils tar gzip

# 创建安装目录
RUN mkdir -p /webroot && mkdir /log && mkdir /config

# 新建nginx用户
RUN adduser --home-dir /webroot --no-create-home  --user-group --system --uid 404 nginx

# 从build容器复制config.tar.gz和nginx.tar.gz

COPY --from=build /config.tar.gz /config.tar.gz
COPY --from=build /nginx.tar.gz /nginx.tar.gz

# 从build容器复制modsecurity和coreruleset
# COPY --from=build /usr/local/modsecurity /usr/local/modsecurity
COPY --from=build /usr/local/coreruleset /usr/local/coreruleset
COPY REQUEST-910-IP-REPUTATION-remove-geo.conf /usr/local/coreruleset/rules/

# 将nginx解压

RUN tar -xzvf  /nginx.tar.gz -C / && \
    rm /nginx.tar.gz

VOLUME ["/log", "/config", "/webroot"]

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

WORKDIR /webroot

EXPOSE 80 443

STOPSIGNAL SIGQUIT

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD ["/app/nginx", "-g", "daemon off;"]




