# Online battle server image. Self-contained: compiles the server from source.
#   docker build -f server.Dockerfile -t blast-server .
#   docker run -p 8080:8080 blast-server
# The server shares game code with the Flutter app, so dependencies are
# resolved with the Flutter SDK. A kernel (.dill) only runs on the exact Dart
# SDK that compiled it, so the runtime stage reuses Flutter's bundled Dart.
FROM ghcr.io/cirruslabs/flutter:3.41.5 AS build
WORKDIR /src
COPY pubspec.yaml pubspec.lock l10n.yaml ./
COPY lib lib
COPY bin bin
RUN flutter pub get
RUN mkdir -p /out \
 && dart compile kernel bin/server.dart -o /out/blast_server.dill \
 && cp -r "$(dirname "$(readlink -f "$(which flutter)")")/cache/dart-sdk" /out/dart-sdk \
 && /out/dart-sdk/bin/dart --version

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /out /app
ENV PORT=8080
EXPOSE 8080
CMD ["/app/dart-sdk/bin/dart", "/app/blast_server.dill"]
