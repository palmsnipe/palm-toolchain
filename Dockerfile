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
COPY . .
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

CMD ["bash"]
