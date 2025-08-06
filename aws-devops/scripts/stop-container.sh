#!/bin/bash

APP_NAME="nginx-app"

# Stop running container if exists
if [ "$(docker ps -q -f name=$APP_NAME)" ]; then
  echo "Stopping running container: $APP_NAME"
  docker stop $APP_NAME || true 
  docker rm $APP_NAME || true
else
  echo "No running container found."
fi
