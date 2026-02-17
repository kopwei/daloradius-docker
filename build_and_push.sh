#!/bin/bash
set -e

IMAGE_NAME="kopwei/daloradius"
TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"

# Check if user is logged in to Docker Hub (optional check, but good for feedback)
if ! docker system info | grep -q "Username"; then
    echo "Warning: You are not logged in to Docker Hub. 'docker push' might fail."
    echo "Please run 'docker login' first if you intend to push."
fi

# Create a builder instance if it doesn't exist
if ! docker buildx ls | grep -q "daloradius-builder"; then
    docker buildx create --name daloradius-builder --use
else
    docker buildx use daloradius-builder
fi

# Build and push
echo "Building and pushing $IMAGE_NAME:$TAG for platforms: $PLATFORMS"
docker buildx build \
    --platform "$PLATFORMS" \
    --tag "$IMAGE_NAME:$TAG" \
    --push \
    daloradius/

echo "Build and push completed successfully!"
