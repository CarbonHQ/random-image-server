FROM clux/muslrust AS builder

# Set the working directory
WORKDIR /app

ARG TARGETARCH

# Copy the source code
COPY src /app/src
COPY Cargo.toml /app/Cargo.toml
COPY Cargo.lock /app/Cargo.lock

# Build the application
RUN case "${TARGETARCH}" in \
        amd64) rust_target="x86_64-unknown-linux-musl" ;; \
        arm64) rust_target="aarch64-unknown-linux-musl" ;; \
        *) echo "Unsupported Docker target architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    cargo build --release --target "${rust_target}" && \
    cp "target/${rust_target}/release/random-image-server" /app/random-image-server

# New stage for the final image
FROM alpine:latest

# Create a user and group for running the application
RUN addgroup --system random-image-server && \
    adduser --system --ingroup random-image-server random-image-server

# Copy the binary from the builder stage
COPY --from=builder /app/random-image-server /usr/local/bin/random-image-server

# Create the configuration directory
RUN mkdir -p /etc/random-image-server

# Set the user and group for the application
USER random-image-server:random-image-server

ENTRYPOINT [ "/usr/local/bin/random-image-server", "/etc/random-image-server/config.toml" ]
