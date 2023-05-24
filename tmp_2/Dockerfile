FROM localhost/tmp_1

ENV NGINX_VERSION 1.22.1

ENV MODSEC_VERSION v3.0.9
ENV MOD_NGX_VERSION v1.0.3

ENV OWASP_VERSION v3.3.4

ENV UPSTREAM_CHECK_VERSION v0.4.0
ENV VTS_VERSION v0.2.1

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

WORKDIR /opt/ModSecurity
RUN git submodule update --init --recursive
