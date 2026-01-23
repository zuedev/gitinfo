# gitinfo

> Markup specification for the .gitinfo file, a way to help discern different hosts of the same repo.

## Overview

The `.gitinfo` file is a simple text file that can be placed in the root directory of a Git repository. It contains metadata about the repository that can help differentiate between different hosts or instances of the same repository. This is particularly useful in scenarios where the same codebase is hosted on multiple platforms (e.g., GitHub, GitLab, Bitbucket) or when working with forks and clones. The `.gitinfo` file can provide information such as the original source of the repository, the intended hosting platforms, or any other relevant details that help identify the context of the repository.

## File Format

The `.gitinfo` file uses JSONC (JSON with Comments) format, allowing for easy readability and the inclusion of comments. The file consists of key-value pairs, where each key represents a specific piece of metadata about the repository.

### Example `.gitinfo` File

```jsonc
{
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

- `root`: The URL of the root repository. This key is mandatory and should point to the main hosting location of the repository that acts as the source of truth for the codebase.
- `gitmail`: An email address associated with the repository for submitting git patches. See [git-send-email.io](https://git-send-email.io/) for details.
- `icon`: A public URL or data URI formatted image (PNG, SVG, etc.) representing an icon for the repository. If using a data URI, we recommend using base64 encoding for compatibility.
- `description`: A brief description of the repository's purpose or contents.
- `tags`: A list of tags or keywords associated with the repository for easier categorization and searchability.
- `mirrors`: A list of URLs representing mirror repositories.
- `maintainers`: A list of maintainers or contributors to the repository, provided as a 2D array with names and email addresses in the format `[[name, email], ...]`. We recommend using this field instead of traditional Git author/committer metadata for better clarity on who is responsible for the repository.
- `license`: The license under which the repository is distributed (e.g., MIT, GPL-3.0). We recommend using the short identifier from [SPDX License List](https://spdx.org/licenses/) for consistency.
