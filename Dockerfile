# This image is based on voidlinux-musl.
# Alpine is only needed to get libgcc.a
FROM alpine:3.9
RUN apk --no-cache add gcc
FROM voidlinux/voidlinux-musl

RUN xbps-install -S -y bash vim gcc make clang flex bison git file curl gmp-devel mpfr-devel rust cargo

# HACK: copy static version of libgcc from Alpine Linix
COPY --from=0 /usr/lib/gcc/x86_64-alpine-linux-musl/8.2.0/libgcc.a /usr/local/lib
COPY --from=0 /usr/lib/gcc/x86_64-alpine-linux-musl/8.2.0/libgcc_eh.a /usr/local/lib

# Build pbc
ENV PBC_SRC=https://crypto.stanford.edu/pbc/files/pbc-0.5.14.tar.gz
RUN curl -L ${PBC_SRC} | tar xvfz - && cd pbc-* && \
     ./configure --enable-static --disable-shared --prefix=/usr/local && \
     make -j && \
     make install && \
     cd .. && \
     rm -rf pbc-*

# Build flint
ENV FLINT_SRC=http://www.flintlib.org/flint-2.5.2.tar.gz
RUN curl -L ${FLINT_SRC} | tar xvfz - && cd flint-* && \
     ./configure --enable-static --disable-shared --prefix=/usr/local && \
     make -j && \
     make install && \
     cd .. && \
     rm -rf flint-*

# Add workarourund for stegos
RUN cp /usr/lib/libgmp.a /usr/local/lib/
RUN cp /usr/lib/libmpfr.a /usr/local/lib/

# Force static linking
ADD rust-static-linker /usr/local/bin
ENV RUSTFLAGS="-Clinker=/usr/local/bin/rust-static-linker"
