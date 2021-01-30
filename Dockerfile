FROM node:15

ARG REPO="https://github.com/Cryptkeeper/Minetrack.git"
ARG SERVERS="https://github.com/neckbeard-cc/servers/releases/latest/download/servers.json"

RUN apt-get update  \
 && apt-get upgrade --quiet --assume-yes \
 && apt-get install --quiet --assume-yes --no-install-recommends \
 curl    \
 git     \
 make    \
 sqlite3

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
 && rm -rf /tmp/minetrack              \
# prepare config
 && sed -i 's/"logFailedPings": true/"logFailedPings": false/g' config.json \
 && sed -i 's/"pingAll": 3000/"pingAll": 10000/g' config.json \
 && rm -f servers.json \
# download servers.json
 && curl --location $SERVERS -o servers.json

# build minetrack
RUN npm install --build-from-source \
 && npm run build

# clean apt packages
RUN apt-get purge --quiet --assume-yes \
 curl \
 git  \
 make \
 && apt-get clean      --quiet --assume-yes \
 && apt-get autoremove --quiet --assume-yes

# run as non root
RUN addgroup --gid 10043 --system minetrack \
 && adduser  --uid 10042 --system --ingroup minetrack --no-create-home --gecos "" minetrack
USER minetrack

EXPOSE 8080

CMD ["node", "main.js"]
