# PowerShell Validator

A PowerShell script for validating `.gitinfo` files.

## Requirements

- PowerShell 5.1+ (Windows) or PowerShell Core 7+ (cross-platform)

## Usage

```powershell
# Validate .gitinfo in current directory
.\Validate-GitInfo.ps1

# Validate a specific file
.\Validate-GitInfo.ps1 -Path "path/to/.gitinfo"
```

## Features

- Parses JSONC (strips `//` and `/* */` comments)
- Validates against the gitinfo JSON Schema
- Checks types, formats (URI, email), and patterns
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

## Notes

On Windows, you may need to adjust the execution policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
