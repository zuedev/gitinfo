# gitinfo

> Markup specification for the .gitinfo file, a way to help discern different hosts of the same repo.

## Overview

The `.gitinfo` file is a simple text file that can be placed in the root directory of a Git repository. It contains metadata about the repository that can help differentiate between different hosts or instances of the same repository. This is particularly useful in scenarios where the same codebase is hosted on multiple platforms (e.g., GitHub, GitLab, Bitbucket) or when working with forks and clones. The `.gitinfo` file can provide information such as the original source of the repository, the intended hosting platforms, or any other relevant details that help identify the context of the repository.

## File Format

The `.gitinfo` file uses JSONC (JSON with Comments) format, allowing for easy readability and the inclusion of comments. The file consists of key-value pairs, where each key represents a specific piece of metadata about the repository.

### Validation

A JSON Schema is available for validating `.gitinfo` files:

```
ttps://forgejo.zue.dev/zuedev/gitinfo/raw/branch/main/gitinfo.schema.json
```

You can reference the schema in your `.gitinfo` file using the `$schema` property for editor autocompletion and validation support.

### Example `.gitinfo` File

```jsonc
{
  "$schema": "ttps://forgejo.zue.dev/zuedev/gitinfo/raw/branch/main/gitinfo.schema.json",
  "root": "https://github.com/example/repository",
  "gitmail": "patches@example.com",
  "icon": "https://example.com/icon.png",
  "description": "Example repository description",
  "tags": ["example", "repository", "gitinfo"],
  "mirrors": [
    "https://gitlab.com/example/repository",
    "https://bitbucket.org/example/repository",
  ],
  "maintainers": [
    ["Alice Smith", "alice@example.com"],
    ["Bob Johnson", "bob@example.com"],
  ],
  "license": "MIT",
}
```

### Supported Keys

All keys are optional. Include only the fields relevant to your project.

- `root`: The URL of the root repository, pointing to the main hosting location that acts as the source of truth for the codebase.
- `gitmail`: An email address associated with the repository for submitting git patches. See [git-send-email.io](https://git-send-email.io/) for details.
- `icon`: A public URL or data URI formatted image (PNG, SVG, etc.) representing an icon for the repository. If using a data URI, we recommend using base64 encoding for compatibility.
- `description`: A brief description of the repository's purpose or contents.
- `tags`: A list of tags or keywords associated with the repository for easier categorization and searchability.
- `mirrors`: A list of URLs representing mirror repositories.
- `maintainers`: A list of maintainers or contributors to the repository, provided as a 2D array with names and email addresses in the format `[[name, email], ...]`. We recommend using this field instead of traditional Git author/committer metadata for better clarity on who is responsible for the repository.
- `license`: The license under which the repository is distributed (e.g., MIT, GPL-3.0). We recommend using the short identifier from [SPDX License List](https://spdx.org/licenses/) for consistency.

### Validation Rules

| Field           | Format                       | Example                                                       |
| --------------- | ---------------------------- | ------------------------------------------------------------- |
| `root`          | Valid URI (http/https)       | `https://github.com/user/repo`                                |
| `gitmail`       | Valid email address          | `patches@example.com`                                         |
| `icon`          | URL (http/https) or data URI | `https://example.com/icon.png` or `data:image/png;base64,...` |
| `mirrors[]`     | Valid URI (http/https)       | `https://gitlab.com/user/repo`                                |
| `maintainers[]` | Tuple of `[name, email]`     | `["Alice", "alice@example.com"]`                              |
| `tags[]`        | Non-empty string             | `"cli"`                                                       |
| `description`   | String                       | Any text                                                      |
| `license`       | SPDX identifier              | `MIT`, `GPL-3.0`, `Apache-2.0`                                |

## Usage

Guidelines for tools and parsers consuming `.gitinfo` files:

### Discovery

1. Look for `.gitinfo` in the repository root directory
2. The file is optional—gracefully handle its absence
3. Parse as JSONC (strip comments before JSON parsing)

### Parsing Recommendations

- Use a JSONC-compatible parser (e.g., `jsonc-parser` for Node.js, `json5` for Python)
- Validate against the JSON Schema when available
- Treat all fields as optional; check for existence before use
- Ignore unknown fields for forward compatibility

### Precedence

When the same repository exists on multiple hosts:

1. The `root` URL, if present, indicates the canonical source
2. If no `root` is specified, treat all instances as equal
3. Mirror URLs in `mirrors[]` are considered secondary copies

### Caching

- Cache parsed `.gitinfo` data per repository clone
- Invalidate cache when the file changes (use file mtime or git hooks)
- Respect HTTP caching headers when fetching remote `icon` URLs
