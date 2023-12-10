#!/bin/bash

# Default file extensions to associate with Visual Studio Code
EXTENSIONS=("py" "js" "ts" "tsx" "css" "java" "cpp" "c" "json" "md" "xml" "sql" "php" "rb" "go" "sh")

# Variables for the VSCode path and custom extensions
VSCODE_PATH=""
CUSTOM_EXTENSIONS=()

# Function to parse command-line arguments
mvassoc_parse_arguments() {
    # Parse command-line arguments for path and extensions
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
            *) # unkown option
                shift # past argument
                ;;
        esac
    done
    # echo "VSCode path: $VSCODE_PATH"
    # echo "Custom extensions: ${CUSTOM_EXTENSIONS[@]}"
}

# Sanitize and set the file extensions to be associated
mvassoc_set_extensions() {
    if [ ${#CUSTOM_EXTENSIONS[@]} -ne 0 ]; then
        echo "Using custom extensions: "
        for i in "${!CUSTOM_EXTENSIONS[@]}"; do
            CUSTOM_EXTENSIONS[$i]=${CUSTOM_EXTENSIONS[$i]#.}
            echo "  .${CUSTOM_EXTENSIONS[$i]}"
        done
        EXTENSIONS=("${CUSTOM_EXTENSIONS[@]}")
        exit 1
    fi 
    
    echo "Using default extensions:"
    for i in "${!EXTENSIONS[@]}"; do
        EXTENSIONS[$i]=${EXTENSIONS[$i]#.}
        echo "  .${EXTENSIONS[$i]}"
    done
}

# Fetch the VSCode bundle ID from the provided path
mdls_fetch_vscode_bundle_id_from_path() {
    # Verify if mdls command is available
    if ! command -v mdls &> /dev/null; then
        echo "Error: mdls command not found. Please ensure macOS is up to date."
        exit 1
    fi

    VSCODE_BUNDLEID=$(mdls "$VSCODE_PATH" | grep kMDItemCFBundleIdentifier | awk -F'"' '{print $2}')
    if [ ! "$VSCODE_BUNDLEID" ]; then
        echo "Error: Bundle ID not found. Please check your VSCode path."
        exit 1
    fi
    echo "$VSCODE_BUNDLEID path set to: $VSCODE_PATH"
    # echo "Bundle ID: $VSCODE_BUNDLEID"
}

# Check if duti is installed, and propose installation via Homebrew if not
duti_check_install() {
    if command -v duti &> /dev/null; then
        echo "duti is already installed."
        return
    fi
    
    echo "duti is not installed."
    read -p "⚠️ Would you like to install it using Homebrew? (y/n): " answer
    [ -n "${answer}" ] && answer=${answer,,}; # lowercase conversion
    if [ "$answer" != "y" ]; then
        echo "duti installation was skipped."
        exit 1
    fi

    # Check if Homebrew is installed, we will not propose to install it
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew package manager (https://brew.sh) required is not installed. Please install it first."
        exit 1
    fi
    echo "⚠️ Installing duti using Homebrew..."
    brew install duti
    sleep 0.5
    echo "duti installation completed."
}

# Associate each extension with Visual Studio Code using duti
mvaassoc_duti_associate_extensions() {
    # Associations confirmation
    read -p "⚠️ Would you like to continue? (Y/n): " answer
    [ -n "$answer" ] && answer=${answer,,};
    if [ "$answer" != "y" ] && [ -n "$answer" ]; then
        echo "Associations skipped. Signing off..."
        exit 1
    fi

    SLEEP_TIME=$(echo "scale=2; 0.25 / ${#EXTENSIONS[@]}" | bc)
    for ext in "${EXTENSIONS[@]}"; do
        sleep $SLEEP_TIME
        echo "Associating .$ext with VS Code"
        duti -s "$VSCODE_BUNDLEID" .$ext all
    done
    sleep 0.5
    echo "Association attempts completed."
}

# Main execution flow of the script
sleep 0.25
mvassoc_parse_arguments "$@"
echo

sleep 0.25
mvassoc_set_extensions
echo 

sleep 0.25
mdls_fetch_vscode_bundle_id_from_path
duti_check_install
echo

sleep 0.5
mvaassoc_duti_associate_extensions
echo 

sleep 0.25
echo "⚠️ Restarting Finder to update icon associations..."
killall Finder
echo 

sleep 0.25
echo "Task attempt completed. Please check the associations. Closing..."
exit 0
