FROM swift
WORKDIR /BUILD
ADD . ./
RUN swift package clean
RUN swift build -c release
RUN mkdir /app/bin
ADD ./Sources/App/Config/envs/production/configDocker.json /app/config/config.json
RUN mv `swift build -c release --show-bin-path` /app/bin/
EXPOSE 8080
RUN ls /app/bin/release/Run
RUN ls /app/config/config.json
WORKDIR /app
RUN rm -fr /BUILD
# ENTRYPOINT ./bin/release/Run serve -e production -b 0.0.0.0
ENTRYPOINT ./bin/release/Run serve -e production -b 0.0.0.0
