# syntax=docker/dockerfile:1.4

FROM ubuntu:focal-20221130 AS builder-echidna
ENV LD_LIBRARY_PATH=/usr/local/lib PREFIX=/usr/local HOST_OS=Linux
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-suggests --no-install-recommends \
        cmake \
        curl \
        git \
        libbz2-dev \
        libgmp-dev \
        libreadline-dev \
        libsecp256k1-dev \
        libssl-dev \
        software-properties-common \
        sudo; \
        rm -rf /var/lib/apt/lists/*; \
        apt-get purge -y -qq --auto-remove -o APT::AutoRemove::RecommendsImportant=false;
        
RUN curl -sSL https://get.haskellstack.org/ | sh
COPY . /echidna/
WORKDIR /echidna
RUN .github/scripts/install-libff.sh
RUN stack upgrade && stack setup && stack install --extra-include-dirs=/usr/local/include --extra-lib-dirs=/usr/local/lib


FROM ubuntu:focal-20221130 AS builder-python3

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-suggests --no-install-recommends \
        gcc \
        python3.8-dev \
        python3.8-venv;
        
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

RUN python3 -m venv /venv && /venv/bin/pip3 install --no-cache --upgrade setuptools pip

RUN /venv/bin/pip3 install --no-cache slither-analyzer solc-select && yes | pip3 uninstall crytic-compile && pip3 install -U https://github.com/crytic/crytic-compile/archive/refs/heads/dev-fix-foundry-options.zip

FROM gcr.io/distroless/python3-debian11:nonroot AS final-distroless

COPY --from=builder-echidna /root/.local/bin/echidna-test /usr/local/bin/echidna-test
COPY --from=builder-python3 /venv /venv
COPY docker/solc-install.py /usr/local/bin/solc-install

ENV PATH="$PATH:/venv/bin"
ENTRYPOINT [ "/usr/local/bin/solc-install", "/usr/local/bin/echidna-test" ]


FROM ubuntu:focal-20221130 AS final-ubuntu


RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-suggests --no-install-recommends \
        ca-certificates \
        locale-gen \
        curl \
        python3 \
        python3-distutils; \
        && rm -rf /var/lib/apt/lists/*
        
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

COPY --from=builder-echidna /root/.local/bin/echidna-test /usr/local/bin/echidna-test
COPY --from=builder-python3 /venv /venv

RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Use unicode
RUN locale-gen C.UTF-8 || true

ENV LANG="C.UTF-8"
ENV PATH="$PATH:/venv/bin"

