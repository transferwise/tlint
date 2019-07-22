# tlint

Command-line utility for linting of configuration files

## Installation

### Linux

```sh
curl -L https://github.com/transferwise/tlint/releases/download/$(curl -s https://raw.githubusercontent.com/transferwise/tlint/master/VERSION.txt)/tlint-linux-amd64 -o /usr/local/bin/tlint && chmod +x /usr/local/bin/tlint
```

### MacOS

```sh
curl -L https://github.com/transferwise/tlint/releases/download/$(curl -s https://raw.githubusercontent.com/transferwise/tlint/master/VERSION.txt)/tlint-darwin-amd64 -o /usr/local/bin/tlint && chmod +x /usr/local/bin/tlint
```

## Usage

```
Usage:
  tlint [flags]
  tlint [command]
 Available Commands:
  help        Help about any command
  properties  Validate properties files
  version     Print the version number of tlint
 Flags:
  -h, --help      help for tlint
  -v, --verbose   Verbose output
 Use "tlint [command] --help" for more information about a command.
```

## Release

Releases are triggered with tagging. A sample release cycle would follow the following steps:
1. Bump the version in `VERSION.txt` file and push to master
2. Execute `git tag x.x.x` (same as the version in VERSION.txt) and `git push origin x.x.x`
