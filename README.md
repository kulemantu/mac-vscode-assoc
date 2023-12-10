# Visual Studio Code File Association Tool

This shell script is designed to easily set file associations to open with Visual Studio Code on macOS systems. It allows users to specify custom file extensions or use a set of default extensions.

## Features

- **Custom File Extensions**: Specify the file extensions that you want to associate with Visual Studio Code.
- **Default Extensions**: Use a predefined list of popular extensions for developers.
- **Ease of Use**: Simple command-line interface for quick setup.
- **Homebrew Integration**: Automatically checks for and installs `duti` using Homebrew if not already installed.

## Requirements

- macOS operating system
- [Homebrew](https://brew.sh) (for installing `duti` if not installed)
- `duti` command-line tool

## Usage

1. **Clone the Repository**:
   ```
   git clone https://github.com/kulemantu/mac-vscode-assoc
   cd mac-vscode-assoc
   ```

2. **Run the Script**:
   - To use default extensions:
     ```
     ./mvscassoc.sh --path "/path/to/Visual Studio Code.app"
     ```
   - To specify custom extensions:
     ```
     ./mvscassoc.sh --path "/path/to/Visual Studio Code.app" --ext py js html css
     ```

3. **Follow the Prompts**: The script will guide you through the process.

## Customizing Extensions

You can customize the list of file extensions that you want to associate with Visual Studio Code. Simply pass the extensions as arguments to the script using the `--ext` flag.

Example:
```
./mvscassoc.sh --path "/path/to/Visual Studio Code.app" --ext go rb php
```

## Contributing

Contributions to improve the script or suggestions for new features are welcome.

## License

[Specify the License here, if applicable]

## Disclaimer

This script modifies system-level settings for file associations. Please use it at your own risk. Always ensure that you have backups of important data.
