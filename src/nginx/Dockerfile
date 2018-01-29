FROM alpine:3.7
USER root

ENV NGINX_UID=1000 \
    NGINX_VERSION=nginx-1.12.2 \
    LUAJIT_VERSION=2.1.0-beta3 \
    HTTP_PORT=80 \
    HTTPS_PORT=443 \
    WS_PORT=443 \
    UNMS_HTTP_PORT=8081 \
    UNMS_WS_PORT=8082 \
    PUBLIC_HTTPS_PORT=443 \
    SECURE_LINK_SECRET=enigma

RUN devDeps="wget openssl-dev pcre-dev zlib-dev build-base libffi-dev python-dev build-base" \
    && apk add --no-cache --update ${devDeps} sudo dumb-init openssl pcre libgcc gettext py-pip \
    && pip install certbot==0.21.0 \
    && mkdir -p /tmp/src && cd /tmp/src \
    && wget -q http://nginx.org/download/${NGINX_VERSION}.tar.gz -O nginx.tar.gz \
    && wget -q https://github.com/openresty/lua-nginx-module/archive/v0.10.11.tar.gz -O lua-nginx-module.tar.gz \
    && wget -q https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz -O ndk.tar.gz \
    && wget -q http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz -O luajit.tar.gz \
    && tar -zxvf lua-nginx-module.tar.gz \
    && tar -zxvf ndk.tar.gz \
    && tar -zxvf luajit.tar.gz \
    && tar -zxvf nginx.tar.gz \
    && cd /tmp/src/LuaJIT-${LUAJIT_VERSION} && make amalg PREFIX='/usr' && make install PREFIX='/usr' \
    && export LUAJIT_LIB=/usr/lib/libluajit-5.1.so && export LUAJIT_INC=/usr/include/luajit-2.1 \
    && cd /tmp/src/${NGINX_VERSION} && ./configure \
        --with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
        --with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -fPIC' \
        --with-pcre-jit \
        --with-threads \
        --add-module=/tmp/src/lua-nginx-module-0.10.11 \
        --add-module=/tmp/src/ngx_devel_kit-0.3.0 \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_gzip_static_module \
        --with-http_secure_link_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-http_upstream_ip_hash_module \
        --without-http_memcached_module \
        --without-http_auth_basic_module \
        --without-http_userid_module \
        --without-http_fastcgi_module \
        --without-http_uwsgi_module \
        --without-http_scgi_module \
        --prefix=/var/lib/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/dev/stdout \
        --error-log-path=/dev/stderr \
        --lock-path=/tmp/nginx.lock \
        --pid-path=/tmp/nginx.pid \
        --http-client-body-temp-path=/tmp/body \
        --http-proxy-temp-path=/tmp/proxy \
    && make \
    && make install \
    && apk del ${devDeps} \
    && rm /usr/bin/luajit-${LUAJIT_VERSION} \
    && rm -rf /tmp/src \
    && rm -rf /var/cache/apk/* \
    && echo "unms ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s *" >> /etc/sudoers \
    && echo "unms ALL=(ALL) NOPASSWD:SETENV: /copy-user-certs.sh reload" >> /etc/sudoers

COPY entrypoint.sh cert.sh letsencrypt.sh fill-template.sh copy-user-certs.sh openssl.cnf *.conf.template 502.html /

RUN chmod +x /entrypoint.sh /cert.sh /letsencrypt.sh /fill-template.sh /copy-user-certs.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
