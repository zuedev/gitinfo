# Contributing to gitinfo

Thank you for your interest in improving the `.gitinfo` specification!

## Proposing Changes

### For Minor Clarifications

- Open an issue describing the ambiguity or unclear wording
- Suggest specific text improvements
- Reference relevant sections of the README

### For New Fields

Before proposing a new field:

1. **Check existing issues** to avoid duplicates
2. **Describe the use case** — what problem does this field solve?
3. **Show compatibility** — how does it interact with existing fields?
4. **Provide examples** — include sample `.gitinfo` snippets

Open an issue with the following template:

````markdown
## Proposed Field: `fieldName`

**Type:** string | array | object

**Description:** Brief description of the field's purpose.

**Use Case:** Why is this field needed? What problem does it solve?

**Example:**

```jsonc
{
  "fieldName": "example value",
}
```
````

**Compatibility:** How does this interact with existing fields?

```

### For Breaking Changes

Breaking changes require strong justification:

- Explain why the change cannot be made backward-compatible
- Propose a migration path for existing `.gitinfo` files
- Consider versioning implications

## Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-field`)
3. Update both `README.md` and `gitinfo.schema.json`
4. Ensure the schema validates your examples
5. Submit a pull request with a clear description

## Style Guidelines

- Keep descriptions concise
- Use consistent terminology with existing documentation
- Follow JSONC conventions (trailing commas are allowed)
- Use SPDX identifiers for license references

## Questions?

Open an issue for discussion before investing significant effort in a proposal.
```
