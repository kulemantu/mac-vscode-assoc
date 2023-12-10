# Visual Studio Code File Association Tool

This shell script, designed for macOS systems, streamlines the process of setting file associations to open with Visual Studio Code. It is particularly useful for developers who prefer VS Code as their primary code editor and wish to open various file types directly in it.

## Features

- **Custom File Extensions**: Allows specifying custom file extensions to associate with Visual Studio Code.
- **Default Extensions**: Comes with a predefined set of popular extensions for developers, covering a wide range of programming languages and markup formats.
- **Ease of Use**: Offers a simple command-line interface for quick and intuitive setup.
- **Homebrew Integration**: If required, the script checks for the presence of `duti` (a command-line utility for managing file associations on macOS) and offers to install it using Homebrew.

## Requirements

- macOS operating system.
- [Homebrew](https://brew.sh) - Required for the installation of `duti` if it's not already installed on the system.
- `duti` - A command-line tool used for setting file associations on macOS.

## Usage

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/kulemantu/mac-vscode-assoc
   cd mac-vscode-assoc
   ```

2. **Run the Script**:
   - To use the default set of extensions:
     ```bash
     ./mvscassoc.sh --path "/path/to/Visual Studio Code.app"
     ```
   - To specify custom extensions:
     ```bash
     ./mvscassoc.sh --path "/path/to/Visual Studio Code.app" --ext py js html css
     ```

3. **Follow the Prompts**: The script provides clear instructions and confirms actions at each step, ensuring a user-friendly experience.

## Customizing Extensions

Customize the file extensions associated with Visual Studio Code by passing them as arguments using the `--ext` flag. The script will process these extensions, ensuring they are correctly formatted and associated.

Example:
```bash
./mvscassoc.sh --path "/path/to/Visual Studio Code.app" --ext go rb php
```

## Detailed Script Functionality

- **Argument Parsing**: The script robustly handles command-line arguments, allowing for flexible specification of the Visual Studio Code path and custom file extensions.
- **Extension Sanitization and Setting**: It sanitizes the provided extensions (removing any leading dots) and sets them up for association with VS Code.
- **Bundle ID Retrieval**: Fetches the bundle ID of Visual Studio Code from the specified path, ensuring the correct application is targeted for file association.
- **duti Installation Check**: If `duti` is not installed, the script offers to install it via Homebrew, handling dependencies seamlessly.

## Contributing

Contributions, suggestions for improvements, and feature requests are warmly welcomed. Feel free to fork the repository, make changes, and submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This script alters system-level file association settings. While every effort has been made to ensure its reliability, please use it cautiously. Ensure you have backups of crucial data and use the script at your own risk.
