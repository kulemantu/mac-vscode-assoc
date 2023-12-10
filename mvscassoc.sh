#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default file extensions to associate with Visual Studio Code
EXTENSIONS=("py" "js" "ts" "tsx" "css" "java" "cpp" "c" "json" "md" "xml" "sql" "php" "rb" "go" "sh")

# Variables for the path to Visual Studio Code and custom file extensions
VSCODE_PATH=""
CUSTOM_EXTENSIONS=()

# Function to parse command-line arguments
mvscassoc_parse_arguments() {
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
mvscassoc_set_extensions() {
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


# Function to fetch the Visual Studio Code bundle ID from the provided path
mdls_fetch_vscode_bundle_id_from_path() {
    # First, ensure that the 'mdls' command is available on the system.
    # The 'mdls' command is used to get metadata attributes for a specified file in macOS.
    if ! command -v mdls &> /dev/null; then
        # If 'mdls' command is not found, print an error message and exit.
        # This check is crucial as the function relies on 'mdls' to retrieve the bundle ID.
        echo "${RED}Error: mdls command not found. Please ensure macOS is up to date.${NC}"
        exit 1
    fi

    # Use 'mdls' to get the bundle identifier of the VS Code application.
    # The command extracts metadata from the provided VSCode application path.
    VSCODE_BUNDLEID=$(mdls "$VSCODE_PATH" | grep kMDItemCFBundleIdentifier | awk -F'"' '{print $2}')

    # Check if the bundle ID was successfully retrieved.
    if [ ! "$VSCODE_BUNDLEID" ]; then
        # If the bundle ID is not found, print an error message and exit.
        # A missing bundle ID indicates an issue with the provided VSCode path.
        echo "${RED}Error: Bundle ID not found. Please check your VSCode path.${NC}"
        exit 1
    fi

    # Print the retrieved bundle ID and the path it was set to.
    # This output is useful for confirming that the correct bundle ID was obtained.
    echo "${GREEN}$VSCODE_BUNDLEID package is in '$VSCODE_PATH'.${NC}"
    # Uncomment the line below to directly display the Bundle ID.
    # echo "Bundle ID: $VSCODE_BUNDLEID"
}


# Function to check if 'duti' is installed and install it using Homebrew if not
duti_check_install() {
    # Check if the 'duti' command is available on the system
    if command -v duti &> /dev/null; then
        # If 'duti' is already installed, inform the user and exit the function
        echo "${GREEN}duti is already installed.${NC}"
        return 0
    fi

    # If 'duti' is not installed, inform the user
    echo "${YELLOW}duti is not installed.${NC}"

    # Prompt the user to install 'duti' using Homebrew
    read -p "⚠️ Would you like to install it using Homebrew? (y/n): " answer

    # Convert the user's answer to lowercase for consistent comparison
    [ -n "${answer}" ] && answer=${answer,,}; 

    # If the user's response is not 'y', skip the installation and exit
    if [ "$answer" != "y" ]; then
        echo "duti installation was skipped."
        exit 1
    fi

    # Before proceeding with 'duti' installation, ensure Homebrew is installed
    if ! command -v brew &> /dev/null; then
        # If Homebrew is not installed, inform the user and provide instructions
        echo "${RED}Error: Homebrew package manager (https://brew.sh) required is not installed. Please install it first.${NC}"
        exit 1
    fi

    # If Homebrew is installed, proceed with installing 'duti'
    echo
    echo "⚠️ Installing duti using Homebrew..."
    brew install duti

    # Wait briefly before confirming completion
    echo
    sleep 0.5
    echo "duti installation completed."
}


# Function to associate each specified file extension with Visual Studio Code using the 'duti' utility
mvscassoc_duti_associate_extensions() {
    # Prompt the user for confirmation before proceeding with file associations
    # This is a safety measure to ensure the user is ready to make the changes
    read -p "⚠️ Would you like to continue? (Y/n): " answer

    # Convert the response to lowercase for consistent comparison
    [ -n "$answer" ] && answer=${answer,,};

    # Check if the user's response is not 'y' (yes) and is not an empty string
    # If so, skip the association process and exit the script
    if [ "$answer" != "y" ] && [ -n "$answer" ]; then
        echo "  Associations skipped. Signing off..."
        exit 1
    fi

    echo
    # Calculate the time to sleep between each association attempt
    # This is done to prevent overwhelming the system with rapid successive commands
    # The time is calculated based on the number of extensions to be processed
    SLEEP_TIME=$(echo "scale=2; 0.25 / ${#EXTENSIONS[@]}" | bc)

    # Loop through each file extension in the EXTENSIONS array
    for ext in "${EXTENSIONS[@]}"; do
        # Sleep for the calculated duration to pace the association commands
        sleep $SLEEP_TIME

        # Echo the current operation to inform the user
        # This indicates which file extension is currently being associated with VS Code
        echo "  Associating .$ext with VS Code"

        # Execute the 'duti' command to associate the current file extension with VS Code
        # This uses the bundle ID of VS Code and the file extension to set the association
        duti -s "$VSCODE_BUNDLEID" .$ext all
    done
    
    # After processing all extensions, inform the user that the operation is complete
    echo
    sleep 0.5
    echo "${GREEN}Association attempts completed.${NC}"
}


# ---------------------------------
# MAIN execution flow of the script
# ---------------------------------

# Print a newline for better output readability
echo 
echo "${GREEN}Starting the Visual Studio Code File Association Tool...${NC}"

# Short pause for better output readability
sleep 0.25

# Parse the command-line arguments provided to the script
# This function sets the VSCode path and custom extensions if provided
mvscassoc_parse_arguments "$@"

# Add a newline for output separation
echo

# Short pause before processing extensions
sleep 0.25

# Set the file extensions to be associated with VSCode
# This function uses either the provided custom extensions or the default set
mvscassoc_set_extensions

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
mvscassoc_duti_associate_extensions

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
echo "${GREEN}Task attempt completed. Please check the associations.${NC}"
echo "Closing..."

# Exit the script
exit 0
