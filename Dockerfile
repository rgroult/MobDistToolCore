FROM swift
WORKDIR /app
RUN swift package clean
RUN swift build -c release
RUN mkdir /app/bin
ADD ./Sources/App/Config/envs/production/configDocker.json /app/bin/config/config.json
RUN mv `swift build -c release --show-bin-path`/release /app/bin/
EXPOSE 8080
ENTRYPOINT ./bin/release/Run serve -e production -b 0.0.0.0
