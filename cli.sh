#!/bin/bash

echo "System informations for host: $(hostname):"
echo "-------------------------------------------"

# Function to display help
display_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -u, --uptime        Display uptime"
  echo "  -d, --distroname    Display distribution name"
  echo "  -v, --kernel-version Display kernel version"
  echo "  -a, --architecture  Display architecture"
  echo "  -m, --memory        Display memory information"
  echo "  -s, --user          Display current user"
  echo "  -r, --folder <path> Specify folder for file creation"
  echo "  -f, --file <path>   Specify file path"
  echo "  -l, --links <path>  Specify directory for links"
  echo "  -h, --help          Display this help message"
  echo "  --show-container    List all docker containers"
  echo "  --build-docker --name <image_name> Builds docker image from Dockerfile"
  echo "  --remove-image --image-name <image_name> Removes a docker image"
  exit 0
}

# Check for NO parameters *BEFORE* the loop
if [[ $# -eq 0 ]]; then
  display_help  # Display help if no arguments
fi

# Initialize variables
folder=""
file=""
links_dir=""
image_name=""
build_docker=false
remove_image=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--uptime) echo "Uptime: $(uptime)"; shift;;
    -d|--distroname) DISTRONAME=$(lsb_release -a | grep "Description:" | awk -F: '{print $2}' | tr -d '[:space:]'); echo "Distribution: $DISTRONAME"; shift;;
    -v|--kernel-version) echo "Kernel version: $(uname -r)"; shift;;
    -a|--architecture) echo "Architecture: $(uname -m)"; shift;;
    -m|--memory) TOTALMEM=$(free -m | grep Mem | awk '{print $2}'); FREEMEM=$(free -m | grep Mem | awk '{print $4}'); echo "Total memory: $TOTALMEM GiB"; echo "Free memory: $FREEMEM GiB"; shift;;
    -s|--user) echo "Current user: $(whoami)"; shift;;
    -r|--folder)
      if [[ -z "$2" ]]; then
        echo "Error: Option $1 requires an argument."
        exit 1
      fi
      folder="$2"; shift 2;;
    -f|--file)
      if [[ -z "$2" ]]; then
        echo "Error: Option $1 requires an argument."
        exit 1
      fi
      file="$2"; shift 2;;
    -l|--links)
      if [[ -z "$2" ]]; then
        echo "Error: Option $1 requires an argument."
        exit 1
      fi
      links_dir="$2"; shift 2;;
    -h|--help) display_help;;  # Help option
    --show-container) docker ps -a;; #docker container list
    --build-docker) build_docker=true; shift;;
    --name)
      if [[ -z "$2" ]]; then
        echo "Error: Option $1 requires an argument."
        exit 1
      fi
      image_name="$2"; shift 2;;
    --remove-image) remove_image=true; shift;;
    --image-name)
        if [[ -z "$2" ]]; then
                echo "Error: Option $1 requires an argument."
                exit 1
        fi
        image_name="$2"; shift 2;;
    *) echo "Invalid option: $1"; exit 1;;
  esac
  shift
done

# Check if -r, -f, and -l are all provided *only if any of them were given*
if [[ ! -z "$folder" || ! -z "$file" || ! -z "$links_dir" ]]; then #check if at least one of them is set
  if [[ -z "$folder" || -z "$file" || -z "$links_dir" ]]; then
    echo "Error: The -r/--folder, -f/--file, and -l/--links options must be used together."
    exit 1
  fi

  # ... (rest of the file/link creation code as before)
  if [[ ! -d "$folder" ]]; then
    mkdir -p "$folder" || { echo "Error: Could not create directory '$folder'"; exit 1; }
  fi

  echo "Ahoj" > "$file" || { echo "Error: File '$file' is not writable."; exit 1; }

  mkdir -p "$links_dir" || { echo "Error: Could not create links directory '$links_dir'"; exit 1; }

  ln -s "$file" "$links_dir/softlink" || { echo "Error: Could not create symbolic link."; exit 1; }
  ln "$file" "$links_dir/hardlink" || { echo "Error: Could not create hard link."; exit 1; }

  echo "File and links created successfully!"
fi

# Docker build logic
if $build_docker; then
  if [[ -z "$image_name" ]]; then
    echo "Error: --name option is required with --build-docker"
    exit 1
  fi

  if [[ ! -f "Dockerfile" ]]; then
    echo "Error: Dockerfile not found in the current directory."
    exit 1
  fi

  docker build -t "$image_name" .
  if [[ $? -ne 0 ]]; then
    echo "Error: Docker build failed."
    exit 1
  fi
  echo "Docker image '$image_name' built successfully."
fi

# Docker remove image logic
if $remove_image; then
  if [[ -z "$image_name" ]]; then
    echo "Error: --image-name option is required with --remove-image"
    exit 1
  fi

  docker rmi "$image_name"
  if [[ $? -ne 0 ]]; then
    echo "Error: Docker image removal failed."
    exit 1
  fi
  echo "Docker image '$image_name' removed successfully."
fi