# Notion For Linux

Build Notion packages for Linux, using resources extracted from Notion's Windows or macOS packages.

## Prebuilt packages

See [Releases](https://github.com/lucasscvvieira/notion-linux-builder/releases)

## Requirements

1. Install Docker:

   ```sh
   nvm install node
   ```

2. Install `make`:

   Using Ubuntu/Debian:

   ```sh
   sudo apt-get install -y make
   ```

   Using Fedora:
   ```sh
   sudo dnf install -y make
   ```

# Build

- Run the build script for all packages:

```sh
make all
```

- Run the build script for specific packages:

```sh
make build-(flatpak|deb|rpm)
```

- Change PLATFORM and URL to select from Windows or macOS based version