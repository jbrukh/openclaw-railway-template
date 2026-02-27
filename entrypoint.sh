#!/bin/bash
set -e

chown -R openclaw:openclaw /data
chmod 700 /data

# Persist Homebrew to volume (if baked into image)
if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
  if [ ! -d /data/.linuxbrew ]; then
    cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
  fi
  rm -rf /home/linuxbrew/.linuxbrew
  ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew
fi

exec gosu openclaw node src/server.js
