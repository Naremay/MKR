#!/bin/bash

# Function to make an HTTP request
make_http_request() {
  url=$1
  
  # Send the HTTP GET request using curl (you can change it to POST or any other method if needed)
  response=$(curl -s -w "%{http_code}" -o /dev/null "$url")
  
  # Log the response (optional)
  echo "$(date): HTTP request to $url completed with status code $response"
}

# Main loop to send HTTP requests at random intervals between 5 and 10 seconds
while true; do
  # Generate a random sleep time between 5 and 10 seconds
  sleep_time=$((5 + RANDOM % 6))  # This will give a value between 5 and 10
  
  # Make the HTTP request in the background using the & operator
  make_http_request "http://yourserver.com" &  # Replace with your target URL
  
  # Sleep for the random interval
  sleep $sleep_time
done

