FROM fluent/fluentd:v0.14.17-onbuild
MAINTAINER Unif.io, Inc. <support@unif.io>

LABEL CONSUL_VERSION="0.8.3"
LABEL CONSULTEMPLATE_VERSION="0.18.3"

ENV CONSULTEMPLATE_VERSION=0.18.3

# Install requirements for building as virtual deps
# the ruby dev required for fluentd and consul-template
RUN  apk add --update --virtual .build-deps \
        sudo build-base ruby-dev less git unzip gnupg && \
# Install curl and don't remove so it can be used to grab consul IP
     apk add --no-cache --update curl && \
# Install consul template
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    curl -s --output consul-template_${CONSULTEMPLATE_VERSION}_linux_amd64.zip https://releases.hashicorp.com/consul-template/${CONSULTEMPLATE_VERSION}/consul-template_${CONSULTEMPLATE_VERSION}_linux_amd64.zip && \
    curl -s --output consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS https://releases.hashicorp.com/consul-template/${CONSULTEMPLATE_VERSION}/consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS && \
    curl -s --output consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS.sig https://releases.hashicorp.com/consul-template/${CONSULTEMPLATE_VERSION}/consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS.sig && \
    gpg --keyserver keys.gnupg.net --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C && \
    gpg --batch --verify consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS.sig consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS && \
    grep consul-template_${CONSULTEMPLATE_VERSION}_linux_amd64.zip consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /bin consul-template_${CONSULTEMPLATE_VERSION}_linux_amd64.zip && \
    cd / \
# Install gems & plugins for fluentd
 && sudo gem install \
        fluent-plugin-secure-forward \
        fluent-plugin-s3:1.0.0.rc2 --no-document \
        fluent-plugin-statsd-output \
# Clean up and slim down
 && sudo gem sources --clear-all \
 && apk del .build-deps \
 && rm -rf /var/cache/apk/* \
           /home/fluent/.gem/ruby/2.3.0/cache/*.gem \
           /tmp/build

# for log storage (maybe shared with host)
RUN mkdir -p /fluentd/log

# configuration/plugins path (default: copied from .)
RUN mkdir -p /fluentd/etc /fluentd/plugins

COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/

RUN chmod +x /bin/entrypoint.sh
EXPOSE 24284 5140

ENTRYPOINT ["/bin/entrypoint.sh"]

CMD fluentd -c /fluentd/etc/${FLUENTD_CONF} -p /fluentd/plugins $FLUENTD_OPT
