FROM swift:4.2.4
WORKDIR /BUILD
ADD . ./
RUN swift package clean
RUN swift build -c release
RUN mkdir -p /app/bin
ADD ./Sources/App/Config/envs/production/configDockerFull.json /app/config/config.json
RUN mv `swift build -c release --show-bin-path`/Run /app/bin/
EXPOSE 8080
RUN ls /app/bin/Run
RUN ls /app/config/config.json
WORKDIR /app
RUN rm -fr /BUILD
RUN ls -lh /app/bin/
# ENTRYPOINT ./bin/Run serve -e production -b 0.0.0.0
CMD /app/bin/Run serve -e production -b 0.0.0.0
