#!/usr/bin/env node

/**
 * CLI validator for .gitinfo files
 * Usage: node validate.js [file]
 *        node validate.js              # validates .gitinfo in current directory
 *        node validate.js path/to/.gitinfo
 */

const fs = require("fs");
const path = require("path");

// Load the schema (two levels up from validators/nodejs/)
const SCHEMA_PATH = path.join(__dirname, "..", "..", "gitinfo.schema.json");

/**
 * Strip JSONC comments (single-line // and multi-line /* *\/)
 */
function stripJsonComments(jsonc) {
  let result = "";
  let i = 0;
  let inString = false;
  let stringChar = null;

  while (i < jsonc.length) {
    const char = jsonc[i];
    const next = jsonc[i + 1];

    // Track string state
    if (!inString && (char === '"' || char === "'")) {
      inString = true;
      stringChar = char;
      result += char;
      i++;
      continue;
    }

    if (inString) {
      if (char === "\\" && i + 1 < jsonc.length) {
        // Escape sequence
        result += char + jsonc[i + 1];
        i += 2;
        continue;
      }
      if (char === stringChar) {
        inString = false;
        stringChar = null;
      }
      result += char;
      i++;
      continue;
    }

    // Single-line comment
    if (char === "/" && next === "/") {
      while (i < jsonc.length && jsonc[i] !== "\n") {
        i++;
      }
      continue;
    }

    // Multi-line comment
    if (char === "/" && next === "*") {
      i += 2;
      while (
        i < jsonc.length - 1 &&
        !(jsonc[i] === "*" && jsonc[i + 1] === "/")
      ) {
        i++;
      }
      i += 2;
      continue;
    }

    result += char;
    i++;
  }

  return result;
}

/**
 * Simple JSON Schema validator (subset of draft 2020-12)
 */
function validateSchema(data, schema, path = "") {
  const errors = [];

  if (schema.type === "object") {
    if (typeof data !== "object" || data === null || Array.isArray(data)) {
      errors.push(`${path || "root"}: expected object`);
      return errors;
    }

    // Check additionalProperties
    if (schema.additionalProperties === false && schema.properties) {
      const allowed = new Set(Object.keys(schema.properties));
      for (const key of Object.keys(data)) {
        if (!allowed.has(key)) {
          errors.push(`${path || "root"}: unknown property "${key}"`);
        }
      }
    }

    // Validate each property
    if (schema.properties) {
      for (const [key, propSchema] of Object.entries(schema.properties)) {
        if (data[key] !== undefined) {
          errors.push(
            ...validateSchema(data[key], propSchema, `${path}.${key}`),
          );
        }
      }
    }
  } else if (schema.type === "array") {
    if (!Array.isArray(data)) {
      errors.push(`${path}: expected array`);
      return errors;
    }

    if (schema.items) {
      if (Array.isArray(schema.items)) {
        // Tuple validation
        for (let i = 0; i < data.length; i++) {
          const itemSchema = schema.items[i] || {};
          errors.push(...validateSchema(data[i], itemSchema, `${path}[${i}]`));
        }
        if (schema.minItems && data.length < schema.minItems) {
          errors.push(`${path}: expected at least ${schema.minItems} items`);
        }
        if (schema.maxItems && data.length > schema.maxItems) {
          errors.push(`${path}: expected at most ${schema.maxItems} items`);
        }
      } else {
        // Array of same type
        for (let i = 0; i < data.length; i++) {
          errors.push(
            ...validateSchema(data[i], schema.items, `${path}[${i}]`),
          );
        }
      }
    }
  } else if (schema.type === "string") {
    if (typeof data !== "string") {
      errors.push(`${path}: expected string`);
      return errors;
    }

    if (schema.minLength && data.length < schema.minLength) {
      errors.push(`${path}: string too short (min ${schema.minLength})`);
    }

    if (schema.format === "uri") {
      try {
        new URL(data);
      } catch {
        errors.push(`${path}: invalid URI "${data}"`);
      }
    }

    if (schema.format === "email") {
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data)) {
        errors.push(`${path}: invalid email "${data}"`);
      }
    }

    if (schema.pattern) {
      if (!new RegExp(schema.pattern).test(data)) {
        errors.push(`${path}: does not match pattern ${schema.pattern}`);
      }
    }
  }

  return errors;
}

function main() {
  const args = process.argv.slice(2);
  const filePath = args[0] || ".gitinfo";

  // Check if file exists
  if (!fs.existsSync(filePath)) {
    console.error(`Error: File not found: ${filePath}`);
    process.exit(1);
  }

  // Check if schema exists
  if (!fs.existsSync(SCHEMA_PATH)) {
    console.error(`Error: Schema not found: ${SCHEMA_PATH}`);
    process.exit(1);
  }

  // Read and parse schema
  let schema;
  try {
    schema = JSON.parse(fs.readFileSync(SCHEMA_PATH, "utf-8"));
  } catch (err) {
    console.error(`Error parsing schema: ${err.message}`);
    process.exit(1);
  }

  // Read and parse .gitinfo file
  let content;
  try {
    content = fs.readFileSync(filePath, "utf-8");
  } catch (err) {
    console.error(`Error reading file: ${err.message}`);
    process.exit(1);
  }

  let data;
  try {
    const stripped = stripJsonComments(content);
    data = JSON.parse(stripped);
  } catch (err) {
    console.error(`Error parsing JSONC: ${err.message}`);
    process.exit(1);
  }

  // Validate against schema
  const errors = validateSchema(data, schema);

  if (errors.length > 0) {
    console.error(`Validation failed for ${filePath}:`);
    for (const error of errors) {
      console.error(`  - ${error}`);
    }
    process.exit(1);
  }

  console.log(`✓ ${filePath} is valid`);
  process.exit(0);
}

main();
