#!/bin/bash

# Default extensions
EXTENSIONS=("py" "js" "ts" "tsx" "css" "java" "cpp" "c" "json" "md" "xml" "sql" "php" "rb" "go" "sh")

# Initialize variables for path and custom extensions
VSCODE_PATH=""
CUSTOM_EXTENSIONS=()

# ARGUMENTS
# Parse command-line arguments
sleep 0.25
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --path|-p)
            VSCODE_PATH="$2"
            shift # past argument
            shift # past value
            ;;
        --ext)
            while [[ $# -gt 1 && ! $2 == --* ]]; do
                CUSTOM_EXTENSIONS+=("$2")
                shift # past each extension
            done
            shift # past --ext
            ;;
        *)    # unknown option
            shift # past argument
            ;;
    esac
done

# Check for VS Code path
sleep 0.5
if [ -z "$VSCODE_PATH" ]; then
    echo 'No path specified. Signing off...'
    exit 1
fi

# Use custom extensions if provided
sleep 0.25
if [ ${#CUSTOM_EXTENSIONS[@]} -ne 0 ]; then
    # Sanitize extensions by removing leading dots
    for i in "${!CUSTOM_EXTENSIONS[@]}"; do
        CUSTOM_EXTENSIONS[$i]=${CUSTOM_EXTENSIONS[$i]#.}
    done
    # Replace default extensions with custom extensions
    echo "Using custom extensions: ${CUSTOM_EXTENSIONS[@]}"
    EXTENSIONS=("${CUSTOM_EXTENSIONS[@]}")
else 
    echo "Using default extensions: ${EXTENSIONS[@]}"
fi

# VSCODE
sleep 0.25
echo "Using path $VSCODE_PATH"
printf 'Fetching bundle ID... '

VSCODE_BUNDLEID=$(mdls "$VSCODE_PATH" | grep kMDItemCFBundleIdentifier | awk -F'"' '{print $2}')

sleep 0.5
if [ ! "$VSCODE_BUNDLEID" ]; then
    echo && echo "Bundle ID not found. Please check your path." && echo "Signing off..." && exit 1
fi

echo "($VSCODE_BUNDLEID)"
echo

# DUTI
sleep 1
echo "Checking if duti (Homebrew) is installed..."

# Check if duti is installed
sleep 0.25
if ! command -v duti &> /dev/null; then
    echo "duti is not installed."
    echo "Would you like to install it using Homebrew? (y/n): " 
    read answer
    
    [ -n "$answer" ] && answer=${answer,,};
    if [ "answer" = "y" ]; then
        sleep 0.25
        # Install Homebrew if not installed
        if ! command -v brew &> /dev/null
        then
            echo "Homebrew is not installed. Go to https://brew.sh/ to learn more. Signing off..."
            exit 1
        fi

        sleep 0.5
        echo "Installing duti using Homebrew..."
        brew install duti
    else
        echo "duti installation was skipped. Signing off..."
        exit 1
    fi
else
    echo "duti is already installed. Proceeding..."
fi

echo

# ASSOCIATION
sleep 1
# Check if the user wants to associate the extensions with VS Code
printf "The following file types will be associated with Visual Studio Code: "

# Calculate the sleep denominator as 1 divided by the length of the array
# Using bc (Basic Calculator) for floating point division
SLEEP_TIME=$(echo "scale=2; 0.25 / ${#EXTENSIONS[@]}" | bc)
# echo $SLEEP_TIME
for ext in "${EXTENSIONS[@]}"; do
    sleep $SLEEP_TIME
    printf ".$ext "
done
echo

sleep 0.5
read -p "Would you like to continue? (Y/n): " answer
[ -n "$answer" ] && answer=${answer,,};
if [ "$answer" != "y" ] && [ -n "$answer" ]; then
    echo "Associations skipped. Signing off..."
    exit 1
fi
echo

sleep 0.5
echo "Associating extensions with VS Code ($VSCODE_BUNDLEID)..."

sleep 0.25
# Loop through each extension and set VS Code as the default application
for ext in "${EXTENSIONS[@]}"; do
    sleep $SLEEP_TIME
    echo "[.$ext]: Setting VSCode as the default for .$ext files"
    duti -s "$VSCODE_BUNDLEID" .$ext all
done
echo

# Restart Finder to refresh icon cache
sleep 0.5
echo "Restarting Finder to update icon associations... "
killall Finder
echo

sleep 0.25
echo "Task attempted. Please check if the associations were set correctly by opening a file in Finder."

sleep 0.5
echo "Proceeding to close."
exit 0
