FROM swift:5.4
RUN apt-get  update && apt-get install -y libssl-dev zlib1g-dev unzip aapt && apt-get -qqy purge apport && rm -rf /var/lib/apt/lists/*
WORKDIR /BUILD
ADD . ./
RUN export hash=$(cat .git/$(cat .git/HEAD | cut -d' ' -f2)) && echo let MDT_GitCommit = \""${hash}\"" > ./Sources/App/gitCommit.swift
RUN cat ./Sources/App/gitCommit.swift
RUN swift package clean
RUN swift package resolve
RUN swift build -c release --product Run
RUN mkdir -p /app/bin
ADD ./Sources/App/Config/envs/production/configDockerFull.json /app/config/config.json
ADD Public /app/Public/
RUN ls -lhR /app/
RUN mv `swift build -c release --product Run --show-bin-path`/Run /app/bin/
EXPOSE 8080
RUN ls /app/bin/Run
RUN ls /app/config/config.json
WORKDIR /app
RUN rm -fr /BUILD
RUN ls -lh /app/bin/
RUN ls -lh /app/
ENTRYPOINT ["/app/bin/Run", "serve", "-e", "production", "-b", "0.0.0.0"]
#CMD /app/bin/Run serve -e production -b 0.0.0.0
