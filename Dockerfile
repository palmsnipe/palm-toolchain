FROM ubuntu:24.04 AS base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        bison \
        build-essential \
        ca-certificates \
        clang \
        cmake \
        curl \
        flex \
        git \
        gperf \
        libgmp-dev \
        libmpc-dev \
        libmpfr-dev \
        libtool \
        ninja-build \
        nodejs \
        patch \
        pkg-config \
        texinfo \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

FROM base AS builder

WORKDIR /opt/palm-toolchain
COPY Makefile ./
COPY config ./config
COPY patches ./patches
COPY scripts ./scripts
COPY tests ./tests
COPY tools ./tools
RUN make bootstrap-core \
    && make check-core check-arm

FROM base

WORKDIR /opt/palm-toolchain
COPY . .
COPY --from=builder /opt/palm-toolchain/.toolchain/prefix .toolchain/prefix

ENV PALM_TOOLCHAIN_ROOT=/opt/palm-toolchain
ENV PALM_TOOLCHAIN_PREFIX=/opt/palm-toolchain/.toolchain/prefix
ENV PATH="${PALM_TOOLCHAIN_PREFIX}/bin:${PATH}"

RUN make check-core check-arm

LABEL org.opencontainers.image.source="https://github.com/palmsnipe/palm-toolchain" \
      org.opencontainers.image.description="Palm OS cross-development toolchain (SDK not included)" \
      org.opencontainers.image.licenses="MIT"

CMD ["bash"]
