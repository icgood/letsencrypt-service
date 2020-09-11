FROM python:3.8-alpine

VOLUME ["/var/lib/dehydrated", "/etc/ssl/private"]

RUN apk add --no-cache bash curl openssl dateutils

ARG dehydrated_url="https://raw.githubusercontent.com/dehydrated-io/dehydrated/master/dehydrated"
RUN curl -o /usr/local/bin/dehydrated ${dehydrated_url}
RUN chmod +x /usr/local/bin/dehydrated

ARG lexicon_hook_url="https://raw.githubusercontent.com/AnalogJ/lexicon/master/examples/dehydrated.default.sh"
RUN curl -o /usr/local/bin/lexicon-hook.sh ${lexicon_hook_url}
RUN chmod +x /usr/local/bin/lexicon-hook.sh

RUN pip install -U pip wheel setuptools

ARG lexicon_install="dns-lexicon"
RUN apk --update add --virtual build-dependencies python3-dev build-base libffi-dev openssl-dev \
  && pip install ${lexicon_install} \
  && apk del build-dependencies

RUN mkdir -p /etc/dehydrated

COPY run-dehydrated.sh /usr/local/bin

ENV CERTS=
ENV STAGING=
ENV LEXICON_ENV=/run/secrets/lexicon_env
ENV BASEDIR=/var/lib/dehydrated
ENV OUTDIR=/etc/ssl/private

ENTRYPOINT ["run-dehydrated.sh"]
