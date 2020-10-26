#!/bin/bash
set -e

ELECTRON_VERSION=6.1.12
NOTION_BINARY=notion.exe
NOTION_DMG=notion.dmg

if [[ $1 != deb && $1 != rpm && $1 != flatpak ]] || [[ $2 != win && $2 != mac ]] || [ -z "$3" ]; then
  echo Please specify whether you would like to build a DEB package using \
    Windows or macOS sources and download link
  echo Example: ./build.sh [deb/rpm/flatpak] [win/mac] https://desktop-release.notion-static.com/Notion%20Setup%202.0.9.exe
  exit 1
fi

# Check for Notion Windows installer
if [ "$2" == win ]; then
  wget -c $3 -O $NOTION_BINARY
fi

# Check for Notion macOS installer
if [ "$2" == mac ]; then
  wget -c $3 -O $NOTION_DMG
fi

# Check for required commands
check-command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo Missing command: "$1"
    exit 1
  fi
}

# Check commands for create deb package
if [ "$1" == deb ]; then
  commands=(
    node npm asar electron-packager electron-installer-debian
    7z convert fakeroot dpkg
  )
fi

# Check commands for create rpm package
if [ "$1" == rpm ]; then
  commands=(
    node npm asar electron-packager electron-installer-redhat
    7z convert fakeroot dnf
  )
fi

# Check commands for create flatpak package
if [ "$1" == flatpak ]; then
  commands=(
    node npm asar electron-packager electron-installer-flatpak
    7z convert fakeroot flatpak flatpak-builder
  )
fi

for command in "${commands[@]}"; do
  check-command "$command"
done

# Setup the build directory
mkdir -p build

if [ "$2" == win ]; then
  # Extract the Notion executable
  if ! [ -f "build/notion/\$PLUGINSDIR/app-64.7z" ]; then
    7z x $NOTION_BINARY -obuild/notion
  fi

  # Extract the app bundle
  if ! [ -f build/bundle/resources/app.asar ]; then
    7z x "build/notion/\$PLUGINSDIR/app-64.7z" -obuild/bundle
  fi

  # Extract the app container
  if ! [ -d build/app ]; then
    asar extract build/bundle/resources/app.asar build/app
  fi
elif [ "$2" == mac ]; then
  # Extract the Notion disk image
  if ! [ -f 'build/notion/Notion Installer/Notion.app/Contents/Resources/app.asar' ]; then
    7z x $NOTION_DMG -obuild/notion
  fi

  if ! [ -d build/app ]; then
    asar extract \
      'build/notion/Notion Installer/Notion.app/Contents/Resources/app.asar' \
      build/app
  fi
fi

# Install NPM dependencies
if ! [ -f build/app/package-lock.json ]; then
  # Replace package name to fix some issues:
  # - conflicting package in Ubuntu repos called "notion"
  # - icon not showing up properly when only the DEB package is renamed
  sed -i 's/"Notion"/"notion-desktop"/' build/app/package.json

  # Include source platform in version string
  preamble='"version": "'
  sed -i -r "s/$preamble(.+?)\"/$preamble\1-$1\"/" build/app/package.json

  # Remove existing node_modules
  rm -rf build/app/node_modules

  # Configure build settings
  # See https://www.electronjs.org/docs/tutorial/using-native-node-modules
  export npm_config_target=$ELECTRON_VERSION
  export npm_config_arch=x64
  export npm_config_target_arch=x64
  export npm_config_disturl=https://electronjs.org/headers
  export npm_config_runtime=electron
  export npm_config_build_from_source=true

  HOME=~/.electron-gyp npm install --prefix build/app
fi

# Convert icon.ico to PNG
if ! [ -f build/app/icon.png ]; then
  convert 'build/app/icon.ico[0]' build/app/icon.png
fi

# Create Electron distribution
if ! [ -d build/dist ]; then
  electron-packager build/app app \
    --platform linux \
    --arch x64 \
    --out build/dist \
    --electron-version $ELECTRON_VERSION \
    --executable-name notion-desktop
fi

# Create Deb package
if [ "$1" == deb ]; then
  electron-installer-debian \
    --src build/dist/app-linux-x64 \
    --dest dist/installers/ \
    --arch amd64 \
    --options.productName Notion \
    --options.icon build/dist/app-linux-x64/resources/app/icon.png
fi

# Create RPM package
if [ "$1" == rpm ]; then
  electron-installer-redhat \
  --src build/dist/app-linux-x64 \
  --dest dist/installers/ \
  --arch x86_64 \
  --options.productName Notion \
  --options.icon build/dist/app-linux-x64/resources/app/icon.png \
  --options.license OtherLicense
fi

# Create Flatpak package
if [ "$1" == flatpak ]; then
  # Install Flatpak Dependencies
  flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak --user install -y flathub org.freedesktop.Sdk//20.08 org.freedesktop.Platform//20.08 org.electronjs.Electron2.BaseApp//20.08

  # Build Flatpak package
  DEBUG='electron-installer-flatpak' electron-installer-flatpak \
  --src build/dist/app-linux-x64 \
  --dest dist/installers/ \
  --arch x86_64 \
  --options.id so.notion.Notion \
  --options.productName Notion \
  --options.icon build/dist/app-linux-x64/resources/app/icon.png \
  --options.base org.electronjs.Electron2.BaseApp \
  --options.baseVersion 20.08 \
  --options.runtime org.freedesktop.Platform \
  --options.runtimeVersion 20.08 \
  --options.sdk org.freedesktop.Sdk 
fi