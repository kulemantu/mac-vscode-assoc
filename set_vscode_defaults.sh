#!/bin/bash

# Default file extensions to associate with Visual Studio Code
EXTENSIONS=("py" "js" "ts" "tsx" "css" "java" "cpp" "c" "json" "md" "xml" "sql" "php" "rb" "go" "sh")

# Variables for the path to Visual Studio Code and custom file extensions
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
        return 0
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
    echo "$VSCODE_BUNDLEID path set to '$VSCODE_PATH'"
    # echo "Bundle ID: $VSCODE_BUNDLEID"
}

# Check if duti is installed, and propose installation via Homebrew if not
duti_check_install() {
    if command -v duti &> /dev/null; then
        echo "duti is already installed."
        return 0
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

    echo
    echo "⚠️ Installing duti using Homebrew..."
    brew install duti

    echo
    sleep 0.5
    echo "duti installation completed."
}

# Associate each extension with Visual Studio Code using duti
mvaassoc_duti_associate_extensions() {
    # Associations confirmation
    read -p "⚠️ Would you like to continue? (Y/n): " answer
    [ -n "$answer" ] && answer=${answer,,};
    if [ "$answer" != "y" ] && [ -n "$answer" ]; then
        echo "  Associations skipped. Signing off..."
        exit 1
    fi

    echo
    SLEEP_TIME=$(echo "scale=2; 0.25 / ${#EXTENSIONS[@]}" | bc)
    for ext in "${EXTENSIONS[@]}"; do
        sleep $SLEEP_TIME
        echo "  Associating .$ext with VS Code"
        duti -s "$VSCODE_BUNDLEID" .$ext all
    done
    
    echo
    sleep 0.5
    echo "Association attempts completed."
}

# Main execution flow of the script

# Print a newline for better output readability
echo 

# Short pause for better output readability
sleep 0.25

# Parse the command-line arguments provided to the script
# This function sets the VSCode path and custom extensions if provided
mvassoc_parse_arguments "$@"

# Add a newline for output separation
echo

# Short pause before processing extensions
sleep 0.25

# Set the file extensions to be associated with VSCode
# This function uses either the provided custom extensions or the default set
mvassoc_set_extensions

# Add a newline for output separation
echo 

# Short pause before fetching the bundle ID
sleep 0.25

# Fetch the VSCode bundle ID from the provided path
# This function ensures that the correct bundle ID is retrieved for the association process
mdls_fetch_vscode_bundle_id_from_path

# Check for the installation of 'duti' and install it using Homebrew if not present
# 'duti' is a tool required for changing file associations on macOS
duti_check_install

# Add a newline for output separation
echo

# Short pause before starting the association process
sleep 0.5

# Associate the specified file extensions with VSCode using 'duti'
# This function iterates over each extension and sets it to open with VSCode
mvaassoc_duti_associate_extensions

# Add a newline for output separation
echo 

# Short pause before restarting Finder
sleep 0.25

# Restart Finder to apply the updated file associations
# This is required as Finder caches file association information
echo "⚠️ Restarting Finder to update icon associations..."
killall Finder

# Add a newline for output separation
echo 

# Short pause before the final message
sleep 0.25

# Final message indicating that the script has completed its tasks
# Prompt the user to check the updated file associations
echo "Task attempt completed. Please check the associations. Closing..."

# Exit the script
exit 0
