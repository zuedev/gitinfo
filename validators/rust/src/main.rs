use json_comments::StripComments;
use regex::Regex;
use serde_json::Value;
use std::collections::HashSet;
use std::env;
use std::fs;
use std::io::Read;
use std::path::Path;
use std::process;

const RED: &str = "\x1b[0;31m";
const GREEN: &str = "\x1b[0;32m";
const NC: &str = "\x1b[0m";

fn main() {
    let args: Vec<String> = env::args().collect();
    let file_path = args.get(1).map(|s| s.as_str()).unwrap_or(".gitinfo");

    // Find schema path (two levels up from validators/rust/)
    let exe_path = env::current_exe().unwrap_or_default();
    let schema_path = exe_path
        .parent()
        .and_then(|p| p.parent())
        .and_then(|p| p.parent())
        .and_then(|p| p.parent())
        .map(|p| p.join("gitinfo.schema.json"))
        .unwrap_or_else(|| {
            // Fallback: look relative to current directory
            Path::new("../../gitinfo.schema.json").to_path_buf()
        });

    // Also try current working directory relative paths
    let schema_path = if schema_path.exists() {
        schema_path
    } else {
        let cwd_relative = Path::new("gitinfo.schema.json");
        if cwd_relative.exists() {
            cwd_relative.to_path_buf()
        } else {
            // Try from validators/rust/
            Path::new("../../gitinfo.schema.json").to_path_buf()
        }
    };

    if !Path::new(file_path).exists() {
        eprintln!("{}Error: File not found: {}{}", RED, file_path, NC);
        process::exit(1);
    }

    if !schema_path.exists() {
        eprintln!(
            "{}Error: Schema not found: {}{}",
            RED,
            schema_path.display(),
            NC
        );
        process::exit(1);
    }

    // Read and parse schema
    let schema_content = match fs::read_to_string(&schema_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("{}Error reading schema: {}{}", RED, e, NC);
            process::exit(1);
        }
    };
    let schema: Value = match serde_json::from_str(&schema_content) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("{}Error parsing schema: {}{}", RED, e, NC);
            process::exit(1);
        }
    };

    // Read and parse .gitinfo file (with JSONC comment stripping)
    let file_content = match fs::read_to_string(file_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("{}Error reading file: {}{}", RED, e, NC);
            process::exit(1);
        }
    };

    // Strip comments and trailing commas
    let stripped = StripComments::new(file_content.as_bytes());
    let mut json_str = String::new();
    std::io::BufReader::new(stripped)
        .read_to_string(&mut json_str)
        .unwrap();

    // Remove trailing commas (JSONC allows them, JSON doesn't)
    let trailing_comma_re = Regex::new(r",(\s*[}\]])").unwrap();
    let json_str = trailing_comma_re.replace_all(&json_str, "$1");

    let data: Value = match serde_json::from_str(&json_str) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("{}Error parsing JSONC: {}{}", RED, e, NC);
            process::exit(1);
        }
    };

    // Validate
    let errors = validate(&data, &schema);

    if !errors.is_empty() {
        eprintln!("{}Validation failed for {}:{}", RED, file_path, NC);
        for error in &errors {
            eprintln!("  - {}", error);
        }
        process::exit(1);
    }

    println!("{}✓ {} is valid{}", GREEN, file_path, NC);
}

fn validate(data: &Value, schema: &Value) -> Vec<String> {
    let mut errors = Vec::new();

    // Check if root is an object
    if !data.is_object() {
        errors.push("root: expected object".to_string());
        return errors;
    }

    let data_obj = data.as_object().unwrap();
    let properties = schema
        .get("properties")
        .and_then(|p| p.as_object())
        .unwrap();

    // Check additionalProperties
    if schema.get("additionalProperties") == Some(&Value::Bool(false)) {
        let allowed: HashSet<&str> = properties.keys().map(|k| k.as_str()).collect();
        for key in data_obj.keys() {
            if !allowed.contains(key.as_str()) {
                errors.push(format!("root: unknown property \"{}\"", key));
            }
        }
    }

    // Validate each property
    for (key, prop_schema) in properties {
        if let Some(value) = data_obj.get(key) {
            validate_property(&mut errors, &format!(".{}", key), value, prop_schema);
        }
    }

    errors
}

fn validate_property(errors: &mut Vec<String>, path: &str, value: &Value, schema: &Value) {
    let expected_type = schema.get("type").and_then(|t| t.as_str());

    match expected_type {
        Some("string") => {
            if !value.is_string() {
                errors.push(format!("{}: expected string", path));
                return;
            }
            let s = value.as_str().unwrap();

            // Check format
            if let Some(format) = schema.get("format").and_then(|f| f.as_str()) {
                match format {
                    "uri" => {
                        if !is_valid_uri(s) {
                            errors.push(format!("{}: invalid URI \"{}\"", path, s));
                        }
                    }
                    "email" => {
                        if !is_valid_email(s) {
                            errors.push(format!("{}: invalid email \"{}\"", path, s));
                        }
                    }
                    _ => {}
                }
            }

            // Check pattern
            if let Some(pattern) = schema.get("pattern").and_then(|p| p.as_str()) {
                if let Ok(re) = Regex::new(pattern) {
                    if !re.is_match(s) {
                        errors.push(format!("{}: does not match pattern {}", path, pattern));
                    }
                }
            }

            // Check minLength
            if let Some(min_len) = schema.get("minLength").and_then(|m| m.as_u64()) {
                if (s.len() as u64) < min_len {
                    errors.push(format!("{}: string too short (min {})", path, min_len));
                }
            }
        }
        Some("array") => {
            if !value.is_array() {
                errors.push(format!("{}: expected array", path));
                return;
            }
            let arr = value.as_array().unwrap();

            // Validate items
            if let Some(items_schema) = schema.get("items") {
                if items_schema.is_array() {
                    // Tuple validation
                    let items_schemas = items_schema.as_array().unwrap();
                    for (i, item) in arr.iter().enumerate() {
                        if let Some(item_schema) = items_schemas.get(i) {
                            validate_property(errors, &format!("{}[{}]", path, i), item, item_schema);
                        }
                    }
                    // Check minItems/maxItems
                    if let Some(min) = schema.get("minItems").and_then(|m| m.as_u64()) {
                        if (arr.len() as u64) < min {
                            errors.push(format!("{}: expected at least {} items", path, min));
                        }
                    }
                    if let Some(max) = schema.get("maxItems").and_then(|m| m.as_u64()) {
                        if (arr.len() as u64) > max {
                            errors.push(format!("{}: expected at most {} items", path, max));
                        }
                    }
                } else {
                    // Array of same type
                    for (i, item) in arr.iter().enumerate() {
                        validate_property(errors, &format!("{}[{}]", path, i), item, items_schema);
                    }
                }
            }
        }
        Some("object") => {
            if !value.is_object() {
                errors.push(format!("{}: expected object", path));
            }
        }
        _ => {}
    }
}

fn is_valid_uri(s: &str) -> bool {
    s.starts_with("http://") || s.starts_with("https://") || s.starts_with("data:image/")
}

fn is_valid_email(s: &str) -> bool {
    let re = Regex::new(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").unwrap();
    re.is_match(s)
}
