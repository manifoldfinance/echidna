# syntax=docker/dockerfile-upstream:master-experimental
FROM debian:bullseye-20220622 AS builder-echidna

ENV LD_LIBRARY_PATH=/usr/local/lib PREFIX=/usr/local HOST_OS=Linux

RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    DEBIAN_FRONTEND=noninteractivea apt-get update && apt-get install -qqy --assume-yes --no-install-recommends \
    cmake \
    make \
    curl \
    libbz2-dev \
    libgmp-dev \
    build-essential \
    dpkg-sig \
    git \
    libcap-dev \
    libc6-dev \
    libgmp-dev \
    libbz2-dev \
    libreadline-dev \
    libsecp256k1-dev \
    libssl-dev \
    software-properties-common \
    sudo; \
    rm -rf /var/lib/apt/lists/*;
    
WORKDIR /echidna

RUN git clone https://github.com/scipr-lab/libff --recursive && cd libff; \
    git submodule init && git submodule update && git checkout v0.2.1; \
    mkdir -p /echidna/libff/build/make; \
    mkdir -p build/make && cd build; \
    ARGS="-DCMAKE_INSTALL_PREFIX=$PREFIX -DWITH_PROCPS=OFF" CXXFLAGS="" \
    CXXFLAGS="-fPIC $CXXFLAGS" cmake $ARGS .. ; \
    make && make install;
    
RUN curl -sSL https://get.haskellstack.org/ | sh
COPY . /echidna/

RUN stack upgrade && stack setup && stack install --extra-include-dirs=/usr/local/include --extra-lib-dirs=/usr/local/lib

FROM python:3.8.13-slim-bullseye AS wheel

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONUNBUFFERED 1

RUN set -eux; \
# save list of currently installed packages for later so we can clean up
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	DEBIAN_FRONTEND=noninteractive apt-get install -qqy --assume-yes --no-install-recommends \
	linux-libc-dev \
	libc6-dev \
	gcc \
	ca-certificates; \
	rm -rf /var/lib/apt/lists/*;


RUN pip wheel --wheel-dir=/root/wheels slither-analyzer;
RUN pip install --no-cache-dir --upgrade pip
RUN python3 -m venv /venv
# && /venv/bin/pip install --no-cache-dir slither-analyzer;

#FROM gcr.io/distroless/python3-debian11:nonroot AS final
FROM python:3.8.13-slim-bullseye AS final
COPY --from=wheel /root/wheels /root/wheels

# Ignore the Python package index
# and look for archives in
# /root/wheels directory
RUN pip install \
      --no-index \
      --find-links=/root/wheels \
      slither-analyzer
      

COPY --from=builder-echidna /root/.local/bin/echidna-test /usr/local/bin/echidna-test
COPY --from=wheel /venv /venv
#ENV PATH="$PATH:/venv/bin"
ENV PYTHONUNBUFFERED 1

EXPOSE 8545/tcp
EXPOSE 8545/udp
EXPOSE 8180
EXPOSE 3001/tcp
ENTRYPOINT ["/usr/local/bin/echidna-test"]

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Echidna" \
      org.label-schema.description="Foundry Echidna" \
      org.label-schema.url="https://manifoldfinance.com" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/mmanifoldfinance/echidna.git" \
      org.label-schema.vendor="Manifold Finance, Inc." \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"
