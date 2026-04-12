# ============================================================================
# Multi-stage Dockerfile for Swift server-side application
# Builds SwiftTemplateCLI with static Swift stdlib for minimal runtime image
# ============================================================================

# ------ Build stage ------
FROM swift:5.10-jammy AS build

WORKDIR /build

# Layer cache: resolve dependencies before copying source
COPY Package.swift Package.resolved ./
RUN swift package resolve

# Copy source and build
COPY Sources/ Sources/
COPY Tests/ Tests/

RUN swift build -c release \
    --static-swift-stdlib \
    -Xlinker -s \
    && mv .build/release/SwiftTemplateCLI /build/app

# ------ Runtime stage ------
FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/example/swift-template" \
      org.opencontainers.image.description="SwiftTemplate CLI" \
      org.opencontainers.image.licenses="MIT"

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       libcurl4 libxml2 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -r -s /bin/false appuser

COPY --from=build /build/app /usr/local/bin/app

USER appuser

ENTRYPOINT ["app"]
