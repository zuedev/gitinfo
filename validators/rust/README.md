# Rust Validator

A Rust CLI tool for validating `.gitinfo` files.

## Requirements

- Rust 1.70+ (with Cargo)

## Build

```bash
cd validators/rust
cargo build --release
```

The binary will be at `target/release/validate` (or `validate.exe` on Windows).

## Usage

```bash
# Validate .gitinfo in current directory
./target/release/validate

# Validate a specific file
./target/release/validate path/to/.gitinfo
```

Or run directly with Cargo:

```bash
cargo run -- path/to/.gitinfo
```

## Features

- Parses JSONC (strips `//` and `/* */` comments)
- Removes trailing commas (valid in JSONC, invalid in JSON)
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

## Dependencies

- `serde` / `serde_json` - JSON parsing
- `json_comments` - JSONC comment stripping
- `regex` - Pattern matching for validation
