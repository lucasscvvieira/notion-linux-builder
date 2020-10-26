PLATFORM=win
URL="https://desktop-release.notion-static.com/Notion%20Setup%202.0.9.exe"

build-docker-flatpak: ./docker/flatpak.Dockerfile
	docker build -t notion-builder-flatpak:latest -f ./docker/flatpak.Dockerfile .

build-flatpak: build-docker-flatpak
	mkdir -p ./dist/installers
	docker run --privileged --rm --name notion-builder-flatpak -v "$(shell pwd)/dist:/app/dist" notion-builder-flatpak:latest flatpak $(PLATFORM) $(URL)

build-docker-deb: ./docker/deb.Dockerfile
	docker build -t notion-builder-deb:latest -f ./docker/deb.Dockerfile .

build-deb: build-docker-deb
	mkdir -p ./dist/installers
	docker run --rm --name notion-builder-deb -v "$(shell pwd)/dist:/app/dist" notion-builder-deb:latest deb $(PLATFORM) $(URL)

build-docker-rpm: ./docker/rpm.Dockerfile
	docker build -t notion-builder-rpm:latest -f ./docker/rpm.Dockerfile .

build-rpm: build-docker-rpm
	mkdir -p ./dist/installers
	docker run --rm --name notion-builder-rpm -v "$(shell pwd)/dist:/app/dist" notion-builder-rpm:latest rpm $(PLATFORM) $(URL)

all: build-deb build-rpm build-flatpak