FROM fedora:33

# Update system and install Flatpak
RUN dnf -y update \
    && dnf install -y \
    nodejs \
    flatpak \
    flatpak-builder \
    wget \
    p7zip-plugins \
    ImageMagick \
    fakeroot \
    python3 \
    python3-pip \
    && dnf groupinstall -y "Development Tools" \
    && dnf clean all

RUN npm -g install asar electron-packager @malept/electron-installer-flatpak

WORKDIR /app
VOLUME [ "/app/dist" ]

COPY ./build.sh /app/
ENTRYPOINT [ "/app/build.sh" ]
CMD [ "flatpak win" ]