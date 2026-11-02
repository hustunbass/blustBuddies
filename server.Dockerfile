# Online battle server image. Self-contained: compiles the server from source.
#   docker build -f server.Dockerfile -t blast-server .
#   docker run -p 8080:8080 blast-server
# The server shares game code with the Flutter app, so dependencies are
# resolved with the Flutter SDK; the result runs on the plain Dart runtime.
FROM ghcr.io/cirruslabs/flutter:3.41.5 AS build
WORKDIR /src
COPY pubspec.yaml pubspec.lock l10n.yaml ./
COPY lib lib
COPY bin bin
RUN flutter pub get
RUN mkdir -p /out && dart compile kernel bin/server.dart -o /out/blast_server.dill

FROM dart:3.11
WORKDIR /app
COPY --from=build /out/blast_server.dill .
ENV PORT=8080
EXPOSE 8080
CMD ["dart", "blast_server.dill"]
