# using Official stable nginx as base image
FROM nginx:stable-alpine
# Copy the custom index.html file to nginx root directory
COPY nginx-app/index.html /usr/share/nginx/html
# Document that container is listening on port 80
EXPOSE 80