#!/usr/bin/env bash
set -euo pipefail
set -x

# Build for all arches using cross-compiler approach (no QEMU necessary)
# Requirements: Docker with Buildx, or just Docker for a single arch build.

DOCKERFILE=Dockerfile.cross
IMAGE_TAG=nmap-build-cross
ARCHS=${1:-all}

docker build -t ${IMAGE_TAG} -f ${DOCKERFILE} --build-arg ARCHS=${ARCHS} .
if docker buildx version >/dev/null 2>&1; then
	# Prefer buildx so we can build an amd64 base image regardless of host arch
	docker buildx build --platform linux/amd64 -t ${IMAGE_TAG} -f ${DOCKERFILE} --load --build-arg ARCHS=${ARCHS} .
else
	docker build -t ${IMAGE_TAG} -f ${DOCKERFILE} .
fi

mkdir -p output

# Create a container from the image and copy outputs out (the image contains /output)
container=$(docker create --entrypoint /bin/true ${IMAGE_TAG})
docker cp ${container}:/output ./output || true
docker rm ${container} >/dev/null

echo "Cross compilation build complete. Outputs are in ./output"
