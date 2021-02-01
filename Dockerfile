FROM node:lts

ARG REPO="https://github.com/Cryptkeeper/Minetrack.git"
ARG SERVERS="https://github.com/neckbeard-cc/servers/releases/latest/download/servers.json"
ARG TINI="https://github.com/krallin/tini/releases/download/v0.19.0/tini"

RUN apt-get update                                                   \
 && apt-get install    --quiet --yes --no-install-recommends sqlite3 \
 && apt-get clean      --quiet --yes                                 \
 && apt-get autoremove --quiet --yes                                 \
 && rm -rf /var/lib/apt/lists/*

# install tini
RUN curl --location $TINI --output /tini \
 && chmod +x /tini

WORKDIR /usr/src/minetrack

# copy minetrack files
RUN git clone $REPO /tmp/minetrack     \
 && mv /tmp/minetrack/assets .         \
 && mv /tmp/minetrack/lib .            \
 && mv /tmp/minetrack/*.json .         \
 && mv /tmp/minetrack/.babelrc .       \
 && mv /tmp/minetrack/.eslintrc.json . \
 && mv /tmp/minetrack/LICENSE .        \
 && mv /tmp/minetrack/main.js .        \
 && rm -rf /tmp/minetrack

# replace some files
COPY replace/. .

# fetch servers.json
RUN rm -f servers.json \
 && curl --location $SERVERS --output servers.json

# build minetrack
RUN npm install --build-from-source \
 && npm run build

# run as non root
RUN addgroup --gid 10043 --system minetrack \
 && adduser  --uid 10042 --system --ingroup minetrack --no-create-home --gecos "" minetrack \
 && chown -R minetrack:minetrack /usr/src/minetrack
USER minetrack

EXPOSE 8080

ENTRYPOINT ["/tini", "--", "node", "main.js"]
