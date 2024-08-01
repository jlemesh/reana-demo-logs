FROM fluent/fluentd:v1.17.0-debian-amd64-1.0

USER root
WORKDIR /home/fluent
ENV PATH /fluentd/vendor/bundle/ruby/3.2.0/bin:$PATH
ENV GEM_PATH /fluentd/vendor/bundle/ruby/3.2.0
ENV GEM_HOME /fluentd/vendor/bundle/ruby/3.2.0
# skip runtime bundler installation
ENV FLUENTD_DISABLE_BUNDLER_INJECTION 1

COPY Gemfile* /fluentd/
RUN buildDeps="sudo make gcc g++ libc-dev libffi-dev libpq-dev curl" \
  runtimeDeps="" \
      && apt-get update \
     && apt-get upgrade -y \
     && apt-get install \
     -y --no-install-recommends \
     $buildDeps $runtimeDeps net-tools
RUN gem install fluent-plugin-prometheus
RUN gem install fluent-plugin-kubernetes_metadata_filter
RUN fluent-gem install fluent-plugin-multi-format-parser
RUN fluent-gem install fluent-plugin-sql
RUN fluent-gem install pg

# Copy plugins
COPY entrypoint.sh /fluentd/entrypoint.sh

# Environment variables
ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"
# Override LD_PRELOAD in fluentd docker image
# Set "/usr/lib/libjemalloc.so.2" if you want to enable jemalloc explicitly
ENV LD_PRELOAD=""

# Overwrite ENTRYPOINT to run fluentd as root for /var/log / /var/lib
ENTRYPOINT ["tini", "--", "/fluentd/entrypoint.sh"]
