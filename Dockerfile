FROM swift:5.0
RUN apt-get  update && apt-get install libssl-dev zlib1g-dev
WORKDIR /BUILD
ADD . ./
RUN swift package clean
RUN swift package resolve
RUN swift build -c release
RUN mkdir -p /app/bin
ADD ./Sources/App/Config/envs/production/configDockerFull.json /app/config/config.json
ADD Public /app/Public/
RUN ls -lhR /app/
RUN mv `swift build -c release --show-bin-path`/Run /app/bin/
EXPOSE 8080
RUN ls /app/bin/Run
RUN ls /app/config/config.json
WORKDIR /app
RUN rm -fr /BUILD
RUN ls -lh /app/bin/
RUN ls -lh /app/
# ENTRYPOINT ./bin/Run serve -e production -b 0.0.0.0
CMD /app/bin/Run serve -e production -b 0.0.0.0
