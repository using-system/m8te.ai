FROM debian:bookworm-slim AS base
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    libssl-dev \
    libicu72 \
    openssl \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*
RUN groupadd -g 1001 appgroup && useradd -u 1001 -g 1001 -M -s /usr/sbin/nologin appuser
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY accountms.csproj ./
RUN dotnet restore "accountms.csproj"
# Install clang for NativeAOT
RUN apt-get update && apt-get install -y clang
COPY . .
RUN dotnet publish "./accountms.csproj" -c $BUILD_CONFIGURATION -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish/accountms .
RUN chown appuser:appgroup /app/accountms && chmod +x /app/accountms
USER 1001:1001
ENTRYPOINT ["./accountms"]