FROM rust:1.47-alpine as builder
COPY Cargo.toml Cargo.lock ./
COPY src src
RUN cargo install --path .

FROM alpine:latest
COPY --from=builder /usr/local/cargo/bin/spodr-server .
CMD ["./spodr-server"]