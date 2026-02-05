# gitinfo

> Markup specification for the .gitinfo file, a way to help discern different hosts of the same repo.

## Overview

The `.gitinfo` file is a simple text file that can be placed in the root directory of a Git repository. It contains metadata about the repository that can help differentiate between different hosts or instances of the same repository. This is particularly useful in scenarios where the same codebase is hosted on multiple platforms (e.g., GitHub, GitLab, Bitbucket) or when working with forks and clones. The `.gitinfo` file can provide information such as the original source of the repository, the intended hosting platforms, or any other relevant details that help identify the context of the repository.

## Why gitinfo?

Git is decentralized by design—the same repository can exist on multiple hosts, be forked countless times, and cloned to thousands of machines. While this is a strength, it creates challenges:

- **Which copy is canonical?** When a project is mirrored across GitHub, GitLab, Codeberg, and self-hosted instances, there's no standard way to indicate which is the "source of truth."
- **How do I contribute?** Some projects prefer patches via email (`git send-email`), others use pull requests, and some use both. This information often lives only in scattered documentation.
- **Who maintains this?** Git commits show authors, but maintainership changes. A file in the repo can stay current when people move on.
- **Is this a fork or the original?** Forks and mirrors often look identical. Users waste time figuring out which repository to star, watch, or contribute to.

The `.gitinfo` file solves these problems by embedding authoritative metadata directly in the repository—portable, version-controlled, and always available regardless of which host you cloned from.

## File Format

The `.gitinfo` file uses JSONC (JSON with Comments) format, allowing for easy readability and the inclusion of comments. The file consists of key-value pairs, where each key represents a specific piece of metadata about the repository.

### Validation

A JSON Schema is available for validating `.gitinfo` files:

```
https://forgejo.zue.dev/zuedev/gitinfo/raw/branch/main/gitinfo.schema.json
```

You can reference the schema in your `.gitinfo` file using the `$schema` property for editor autocompletion and validation support.

### Example `.gitinfo` File

```jsonc
{
  "$schema": "https://forgejo.zue.dev/zuedev/gitinfo/raw/branch/main/gitinfo.schema.json",
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
  "homepage": "https://example.com/project",
  "funding": [
    "https://github.com/sponsors/example",
    "https://opencollective.com/example",
  ],
  "version": "1.0.0",
}
```

See the [`examples/`](examples/) folder for more sample configurations:

- [`minimal.gitinfo`](examples/minimal.gitinfo) — Bare minimum with just a root URL
- [`open-source-project.gitinfo`](examples/open-source-project.gitinfo) — Full-featured project with mirrors, maintainers, and funding
- [`mirror-only.gitinfo`](examples/mirror-only.gitinfo) — Read-only mirror pointing to upstream

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
- `homepage`: The URL of the project's homepage or documentation site, if separate from the repository.
- `funding`: A list of URLs for sponsorship or funding platforms (e.g., GitHub Sponsors, Open Collective, Patreon).
- `version`: The version of the `.gitinfo` schema being used for this file. Can be a semver string (e.g., `1.0.0`) or a git commit hash.
- `ci`: The URL of the CI/CD platform or pipeline status page for the repository.
- `issues`: The URL of the issue tracker, if different from the root repository.
- `chat`: The URL of a community chat platform (e.g., Discord, Matrix, Slack, IRC).
- `docs`: The URL of the project's documentation site.

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
| `homepage`      | Valid URI (http/https)       | `https://example.com/project`                                 |
| `funding[]`     | Valid URI (http/https)       | `https://github.com/sponsors/user`                            |
| `version`       | Semver or commit hash        | `1.0.0`, `a1b2c3d4e5f6...`                                    |
| `ci`            | Valid URI (http/https)       | `https://github.com/user/repo/actions`                        |
| `issues`        | Valid URI (http/https)       | `https://github.com/user/repo/issues`                         |
| `chat`          | Valid URI (http/https)       | `https://discord.gg/example`                                  |
| `docs`          | Valid URI (http/https)       | `https://docs.example.com`                                    |

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

## FAQ

### Should `.gitinfo` be committed to the repository?

Yes. The file should be version-controlled so it travels with the codebase across all hosts and clones.

### What if different hosts have conflicting `.gitinfo` files?

The `root` repository is authoritative. If someone modifies `.gitinfo` on a mirror, the change should be merged upstream to `root` or discarded. Tools should warn users when a mirror's `.gitinfo` differs from the root.

### Can I use `.gitinfo` in a fork?

Yes. Forks may have their own `.gitinfo` pointing to the fork as `root`, or they can keep the original `root` and add themselves to `mirrors[]`. The choice depends on whether the fork is intended as a permanent divergence or a temporary contribution branch.

### What happens if `root` points to a URL that no longer exists?

Parsers should handle dead links gracefully. Consider falling back to mirrors if available, or simply reporting the metadata without verifying URL accessibility.

### Should I include `.gitinfo` in `.gitignore`?

No. The file is meant to be shared across all clones and hosts.

### Can I add custom fields?

The schema uses `additionalProperties: false` for strict validation. If you need custom metadata, consider opening an issue to propose additions to the spec. For local experimentation, you can use a separate file or fork the schema.

### How do I handle private repositories?

All fields are optional. For private repos, you may omit `root` and `mirrors` if the URLs shouldn't be exposed, while still using `description`, `maintainers`, and other metadata internally.

### What's the difference between `root` and `mirrors`?

- `root`: The single source of truth—where authoritative changes are made
- `mirrors`: Read-only copies that sync from `root`, or alternative access points

## Contributing

Want to propose changes to the specification? See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting issues and pull requests.
