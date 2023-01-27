# 
# https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2004-Readme.md#cached-docker-images
FROM ubuntu@sha256:0e0402cd13f68137edb0266e1d2c682f217814420f2d43d300ed8f65479b14fb AS builder-echidna

ENV LD_LIBRARY_PATH=/usr/local/lib PREFIX=/usr/local HOST_OS=Linux
RUN set -eux; \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qqy --assume-yes --no-install-recommends \
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
        rm -rf /var/lib/apt/lists/*;

RUN curl -sSL https://get.haskellstack.org/ | sh
COPY . /echidna/
WORKDIR /echidna
RUN .github/scripts/install-libff.sh
RUN stack upgrade && stack setup && stack install --flag echidna:static --extra-include-dirs=/usr/local/include --extra-lib-dirs=/usr/local/lib


FROM ubuntu@sha256:0e0402cd13f68137edb0266e1d2c682f217814420f2d43d300ed8f65479b14fb AS builder-python3
RUN set -eux; \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qqy --assume-yes --no-install-recommends \
        gcc \
        python3.8-dev \
        python3.8-venv
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
RUN python3 -m venv /venv && /venv/bin/pip3 install --no-cache --upgrade setuptools pip
RUN /venv/bin/pip3 install --no-cache slither-analyzer solc-select "crytic-compile @ https://github.com/crytic/crytic-compile/archive/53167f3f3d63b73916b1660312a53fd952f2e3dd.zip"


FROM gcr.io/distroless/python3-debian11:nonroot AS final-distroless
COPY --from=builder-echidna /root/.local/bin/echidna-test /usr/local/bin/echidna-test
COPY --from=builder-python3 /venv /venv
COPY docker/solc-install.py /usr/local/bin/solc-install
ENV PATH="$PATH:/venv/bin"
ENTRYPOINT [ "/usr/local/bin/solc-install", "/usr/local/bin/echidna-test" ]


FROM ubuntu@sha256:0e0402cd13f68137edb0266e1d2c682f217814420f2d43d300ed8f65479b14fb AS final-ubuntu
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-suggests --no-install-recommends \
        ca-certificates \
        git \
        curl \
        python3 \
        python3-distutils \
        && \
    rm -rf /var/lib/apt/lists/*
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
COPY --from=builder-echidna /root/.local/bin/echidna-test /usr/local/bin/echidna-test
COPY --from=builder-python3 /venv /venv
ENV LANG="C.UTF-8"
ENV PATH="$PATH:/venv/bin"

ARG VERSION="local"
ARG REVISION="none"
ARG GITHUB_WORKFLOW="none"
ARG GITHUB_RUN_ID="none"
ARG WORKSPACE_DIR=/workspace


# see https://github.blog/2022-04-12-git-security-vulnerability-announced/
RUN git config --global --add safe.directory ${WORKSPACE_DIR}

LABEL github.workflow=${GITHUB_WORKFLOW}
LABEL github.runid=${GITHUB_RUN_ID}
