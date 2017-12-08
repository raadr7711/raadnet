FROM nginx:1-alpine
USER root
COPY entrypoint.sh cert.sh letsencrypt.sh fill-template.sh openssl.cnf *.conf.template 502.html /

RUN apk add --no-cache --update sudo dumb-init openssl nginx-mod-http-lua \
    && apk add --no-cache --update py-urllib3 --repository http://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    && apk add --no-cache --update certbot --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
    && chmod +x /entrypoint.sh /cert.sh /letsencrypt.sh /fill-template.sh \
    && echo "unms ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s *" >> /etc/sudoers

ENTRYPOINT ["/entrypoint.sh"]

# CMD should not be necessary, but inheritance doesn't seem to work
CMD ["nginx", "-g", "daemon off;"]
