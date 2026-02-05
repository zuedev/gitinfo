# Node.js Validator

A zero-dependency Node.js CLI tool for validating `.gitinfo` files.

## Requirements

- Node.js 14+

## Usage

```bash
# Validate .gitinfo in current directory
node validate.js

# Validate a specific file
node validate.js path/to/.gitinfo
```

## Features

- Parses JSONC (strips `//` and `/* */` comments)
- Validates against the gitinfo JSON Schema
- Checks types, formats (URI, email), and patterns
- Enforces `additionalProperties: false`
- Returns exit code 0 on success, 1 on failure

## Example Output

```
✓ .gitinfo is valid
```

```
Validation failed for .gitinfo:
  - .root: invalid URI "not-a-url"
  - root: unknown property "invalid_field"
```
