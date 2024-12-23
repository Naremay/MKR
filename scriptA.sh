#!/bin/bash

# Function to launch a container with the given name and CPU core
launch_container() {
  container_name=$1
  cpu_core=$2
  
  # Launch the container (replace with the actual image you're using for your HTTP server)
  docker run -d --name "$container_name" --cpuset-cpus="$cpu_core" my_http_server_image
  echo "$container_name launched on CPU core $cpu_core"
}

# Function to check if a container is running
is_container_running() {
  container_name=$1
  docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -w "$container_name" > /dev/null
  return $?
}

# Function to pull the latest version of the container image from Docker Hub
pull_latest_image() {
  docker pull my_http_server_image
}

# Function to update a container
update_container() {
  container_name=$1
  
  # Stop and remove the existing container
  docker stop "$container_name"
  docker rm "$container_name"
  
  # Launch the updated container
  launch_container "$container_name" "$(get_container_cpu_core $container_name)"
  
  echo "$container_name updated successfully."
}

# Function to get the CPU core for a given container
get_container_cpu_core() {
  container_name=$1
  case "$container_name" in
    "srv1") echo "0" ;;
    "srv2") echo "1" ;;
    "srv3") echo "2" ;;
    *) echo "Unknown container"; exit 1 ;;
  esac
}

# Function to check if an update is available and update containers
update_if_needed() {
  # Pull the latest version of the image
  pull_latest_image
  
  # Check if srv1 needs to be updated
  if is_container_running "srv1"; then
    update_container "srv1"
  fi

  # Check if srv2 needs to be updated (only if srv1 is running)
  if is_container_running "srv2"; then
    update_container "srv2"
  fi

  # Check if srv3 needs to be updated (only if srv1 or srv2 is running)
  if is_container_running "srv3"; then
    update_container "srv3"
  fi
}

# Main script execution

# Step 1: Launch srv1 on CPU core 0
launch_container "srv1" "0"

# Step 2: Monitor srv1 and launch srv2 on CPU core 1 if necessary
srv1_busy_count=0
while true; do
  if is_container_busy "srv1"; then
    ((srv1_busy_count++))
  else
    srv1_busy_count=0
  fi
  
  if ((srv1_busy_count >= 2)); then
    # Launch srv2 on CPU core 1
    launch_container "srv2" "1"
    srv1_busy_count=0  # Reset the busy count for srv1
    break
  fi
  
  sleep 60  # Check every minute
done

# Step 3: Monitor srv2 and launch srv3 on CPU core 2 if necessary
srv2_busy_count=0
while true; do
  if is_container_busy "srv2"; then
    ((srv2_busy_count++))
  else
    srv2_busy_count=0
  fi
  
  if ((srv2_busy_count >= 2)); then
    # Launch srv3 on CPU core 2
    launch_container "srv3" "2"
    srv2_busy_count=0  # Reset the busy count for srv2
    break
  fi
  
  sleep 60  # Check every minute
done

# Step 4: Periodically check for updates and perform the updates if necessary
while true; do
  update_if_needed
  sleep 3600  # Check for updates every hour
done

echo "All containers are monitored and updated successfully."

