ARG NGINX_VERSION
FROM nginx:${NGINX_VERSION} as base

COPY --chown=nginx:nginx ./images/nginx/conf.d/default.conf /etc/nginx/conf.d

ARG APP_CODE_PATH
RUN sed -i "s#root __NGINX_ROOT;#root $APP_CODE_PATH/public;#" /etc/nginx/conf.d/default.conf

FROM base as local
