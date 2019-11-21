#!/bin/bash

swift build -c release
DEST_DIR=/artifacts
mkdir -p $DEST_DIR/app/bin
mkdir -p $DEST_DIR/app/config
cp ./Sources/App/Config/envs/production/configDockerFull.json $DEST_DIR/app/config/config.json
cp `swift build -c release --show-bin-path`/Run $DEST_DIR/app/bin/
