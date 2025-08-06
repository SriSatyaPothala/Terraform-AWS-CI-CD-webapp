#!/bin/bash

HEALTH_URL="http://localhost/"

for i in {1..10}; do
  echo "Checking $HEALTH_URL"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)
  
  if [ "$STATUS" -eq 200 ]; then
    echo "Health check passed."
    exit 0
  fi

  echo "Health check failed. Retrying in 5s..."
  sleep 5
done

echo "Health check failed after retries."
exit 1
