FROM node:14-slim

RUN apt-get update && apt-get install -y \
    wget \
    p7zip-full \
    imagemagick \
    fakeroot \
    python3 \
    python3-pip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN npm -g install asar electron-packager electron-installer-debian

WORKDIR /app
VOLUME [ "/app/dist" ]

COPY ./build.sh /app/
ENTRYPOINT [ "/app/build.sh" ]
CMD [ "flatpak win" ]
