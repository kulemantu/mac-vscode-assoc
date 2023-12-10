#!/bin/bash

# Default file extensions to associate with Visual Studio Code
EXTENSIONS=("py" "js" "ts" "tsx" "css" "java" "cpp" "c" "json" "md" "xml" "sql" "php" "rb" "go" "sh")

# Variables for the path to Visual Studio Code and custom file extensions
VSCODE_PATH=""
CUSTOM_EXTENSIONS=()

# Function to parse command-line arguments
mvassoc_parse_arguments() {
    # Loop over all arguments passed to the script
    # This allows for handling multiple arguments and flags
    while [[ $# -gt 0 ]]; do
        key="$1"  # Store the current argument in the 'key' variable

        # Use a case statement to handle different types of arguments
        case $key in
            --path|-p)
                # When the --path or -p flag is used, set the next argument as the VSCode path
                VSCODE_PATH="$2"
                shift # Move past the argument ('--path' or '-p')
                shift # Move past the value (the actual path)
                ;;
            --ext)
                # When the --ext flag is used, collect all following arguments as custom extensions
                while [[ $# -gt 1 && ! $2 == --* ]]; do
                    # Add each extension to the CUSTOM_EXTENSIONS array
                    CUSTOM_EXTENSIONS+=("$2")
                    shift # Move past each extension
                done
                shift # Once all extensions are collected, move past the --ext flag
                ;;
            *) # If an unknown option is encountered
                # Simply move past the argument without any action
                shift # This ensures the script doesn't get stuck on an unexpected argument
                ;;
        esac
    done

    # Uncomment the below lines for debugging purposes
    # echo "VSCode path: $VSCODE_PATH"
    # echo "Custom extensions: ${CUSTOM_EXTENSIONS[@]}"
}


# Function to sanitize and set the file extensions to be associated
mvassoc_set_extensions() {
    # Check if custom extensions have been provided through the --ext flag
    if [ ${#CUSTOM_EXTENSIONS[@]} -ne 0 ]; then
        # Inform the user that custom extensions are being used
        echo "Using custom extensions: "

        # Iterate over each custom extension
        for i in "${!CUSTOM_EXTENSIONS[@]}"; do
            # Remove any leading dot (.) from the extension for consistency
            # The '#' character is a parameter expansion operator that removes the shortest match of '.' from the beginning of the string
            CUSTOM_EXTENSIONS[$i]=${CUSTOM_EXTENSIONS[$i]#.}

            # Display each sanitized custom extension
            echo "  .${CUSTOM_EXTENSIONS[$i]}"
        done

        # Set the EXTENSIONS array to the sanitized custom extensions
        EXTENSIONS=("${CUSTOM_EXTENSIONS[@]}")

        # Exit the function successfully
        return 0
    fi 

    # If no custom extensions are provided, use the default set of extensions
    echo "Using default extensions:"

    # Iterate over each default extension
    for i in "${!EXTENSIONS[@]}"; do
        # Ensure each default extension is sanitized (removing any leading dot)
        EXTENSIONS[$i]=${EXTENSIONS[$i]#.}

        # Display each sanitized default extension
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
