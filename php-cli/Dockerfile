FROM php:7.0-cli

RUN apt-get update -yqq \
 && apt-get install -yqq \
    # install sshd
    openssh-server \
    # install ping and netcat (for debugging xdebug connectivity)
    iputils-ping netcat \
    # fix ssh start up bug
    # @see https://github.com/ansible/ansible-container/issues/141
 && mkdir /var/run/sshd \
;

# add default public key to authorized_keys
COPY ./ssh/insecure_id_rsa.pub /root/insecure_id_rsa.pub
RUN mkdir -p /root/.ssh \
 && cat /root/insecure_id_rsa.pub >> /root/.ssh/authorized_keys \
 && rm -rf /root/insecure_id_rsa.pub \
;

RUN pecl -q install xdebug-2.6.0 \
;
COPY ./conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# @see https://docs.docker.com/engine/examples/running_ssh_service/
CMD ["/usr/sbin/sshd", "-D"]

