FROM python:3.8-slim-buster AS base

# requires git to install requirements with git+https
# requires rustc is required to build cryptography wheel
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential git gcc libffi-dev libssl-dev libxml2-dev libxslt1-dev libxslt-dev libjpeg62-turbo-dev zlib1g-dev \
    && apt-get install -y rustc \
    && python -m venv /opt/venv

# Make sure we use the virtualenv:
ENV PATH="/opt/venv/bin:$PATH"

COPY . .
RUN pip install -U setuptools wheel pip>=20.0.0 \
    && pip install Cython==0.29.21 \
    && pip install --extra-index-url https://www.piwheels.org/simple --prefer-binary -r requirements.txt \
    && python setup.py install

FROM python:3.8-slim-buster

ARG TENTACLES_URL_TAG=""
ENV TENTACLES_URL_TAG=$TENTACLES_URL_TAG

WORKDIR /octobot
COPY --from=base /opt/venv /opt/venv
COPY octobot/config /octobot/octobot/config
COPY docker-entrypoint.sh docker-entrypoint.sh

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl libxslt-dev libxcb-xinput0 libjpeg62-turbo-dev zlib1g-dev libblas-dev liblapack-dev libatlas-base-dev libopenjp2-7 libtiff-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /opt/venv/bin/OctoBot OctoBot # Make sure we use the virtualenv \
    && chmod +x docker-entrypoint.sh

VOLUME /octobot/backtesting
VOLUME /octobot/logs
VOLUME /octobot/tentacles
VOLUME /octobot/user
EXPOSE 5001

HEALTHCHECK --interval=1m --timeout=30s --retries=3 CMD curl --fail http://localhost:5001 || exit 1
ENTRYPOINT ["./docker-entrypoint.sh"]
