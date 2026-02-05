# Bash Validator

A Bash script for validating `.gitinfo` files.

## Requirements

- Bash 4+
- [jq](https://jqlang.github.io/jq/) (JSON processor)

Install jq:

```bash
# Debian/Ubuntu
apt install jq

# macOS
brew install jq

# Windows (via Chocolatey)
choco install jq
```

## Usage

```bash
# Make executable (first time only)
chmod +x validate.sh

# Validate .gitinfo in current directory
./validate.sh

# Validate a specific file
./validate.sh path/to/.gitinfo
```

## Features

- Parses JSONC (strips `//` and `/* */` comments)
- Validates against the gitinfo JSON Schema
- Checks types and formats (URI, email)
- Enforces `additionalProperties: false`
- Returns exit code 0 on success, 1 on failure
- Color-coded output (green for success, red for errors)

## Example Output

```
✓ .gitinfo is valid
```

```
Validation failed for .gitinfo:
  - .root: invalid URI "not-a-url"
  - root: unknown property "invalid_field"
```

## Limitations

- Comment stripping is simplified and may not handle edge cases with comments inside strings
- For complex validation, consider using the Node.js validator
