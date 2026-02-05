#!/usr/bin/env bash

# CLI validator for .gitinfo files
# Usage: ./validate.sh [file]
#        ./validate.sh              # validates .gitinfo in current directory
#        ./validate.sh path/to/.gitinfo

set -e

# Schema path (two levels up from validators/bash/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_PATH="$SCRIPT_DIR/../../gitinfo.schema.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}" >&2
    echo "Install with: apt install jq / brew install jq / choco install jq" >&2
    exit 1
fi

# Strip JSONC comments using sed
strip_comments() {
    # Remove carriage returns (Windows line endings), single-line comments, and multi-line comments
    # Also remove trailing commas before } or ] (valid in JSONC, invalid in JSON)
    cat "$1" | tr -d '\r' | sed -e 's|//.*$||g' -e ':a;s|/\*.*\*/||g;ta' -e '/\/\*/,/\*\//d' | sed -e 's/,\s*}/}/g' -e 's/,\s*]/]/g'
}

# Validate URI format
validate_uri() {
    local uri="$1"
    if [[ "$uri" =~ ^https?:// ]]; then
        return 0
    fi
    return 1
}

# Validate email format
validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
        return 0
    fi
    return 1
}

# Main validation function
validate() {
    local file="$1"
    local errors=()
    
    # Parse JSON
    local json
    if ! json=$(strip_comments "$file" | jq -c . 2>&1); then
        echo -e "${RED}Error parsing JSONC: $json${NC}" >&2
        exit 1
    fi
    
    # Load schema
    local schema
    if ! schema=$(jq -c . "$SCHEMA_PATH" 2>&1); then
        echo -e "${RED}Error parsing schema: $schema${NC}" >&2
        exit 1
    fi
    
    # Check if root is an object
    local type
    type=$(echo "$json" | jq -r 'type')
    if [[ "$type" != "object" ]]; then
        errors+=("root: expected object, got $type")
    fi
    
    # Get allowed properties from schema
    local allowed_props
    allowed_props=$(echo "$schema" | jq -r '.properties | keys[]')
    
    # Check for unknown properties
    local actual_props
    actual_props=$(echo "$json" | jq -r 'keys[]')
    for prop in $actual_props; do
        if ! echo "$allowed_props" | grep -qx "$prop"; then
            errors+=("root: unknown property \"$prop\"")
        fi
    done
    
    # Validate each property
    local schema_props
    schema_props=$(echo "$schema" | jq -r '.properties | to_entries[] | @base64')
    
    for entry in $schema_props; do
        local key format prop_type
        key=$(echo "$entry" | base64 -d | jq -r '.key')
        format=$(echo "$entry" | base64 -d | jq -r '.value.format // empty')
        prop_type=$(echo "$entry" | base64 -d | jq -r '.value.type')
        
        # Check if property exists
        local value
        value=$(echo "$json" | jq -r --arg k "$key" '.[$k] // empty')
        
        if [[ -n "$value" && "$value" != "null" ]]; then
            local actual_type
            actual_type=$(echo "$json" | jq -r --arg k "$key" '.[$k] | type')
            
            # Type check
            if [[ "$prop_type" == "string" && "$actual_type" != "string" ]]; then
                errors+=(".$key: expected string")
            elif [[ "$prop_type" == "array" && "$actual_type" != "array" ]]; then
                errors+=(".$key: expected array")
            fi
            
            # Format validation for strings
            if [[ "$actual_type" == "string" ]]; then
                if [[ "$format" == "uri" ]]; then
                    if ! validate_uri "$value"; then
                        errors+=(".$key: invalid URI \"$value\"")
                    fi
                elif [[ "$format" == "email" ]]; then
                    if ! validate_email "$value"; then
                        errors+=(".$key: invalid email \"$value\"")
                    fi
                fi
            fi
            
            # Validate array items
            if [[ "$actual_type" == "array" ]]; then
                local item_format
                item_format=$(echo "$entry" | base64 -d | jq -r '.value.items.format // empty')
                
                if [[ "$item_format" == "uri" ]]; then
                    local i=0
                    while IFS= read -r item; do
                        if ! validate_uri "$item"; then
                            errors+=(".${key}[$i]: invalid URI \"$item\"")
                        fi
                        ((i++))
                    done < <(echo "$json" | jq -r --arg k "$key" '.[$k][]?')
                fi
            fi
        fi
    done
    
    # Output results
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo -e "${RED}Validation failed for $file:${NC}" >&2
        for error in "${errors[@]}"; do
            echo -e "  - $error" >&2
        done
        exit 1
    fi
    
    echo -e "${GREEN}✓ $file is valid${NC}"
    exit 0
}

# Main
FILE="${1:-.gitinfo}"

if [[ ! -f "$FILE" ]]; then
    echo -e "${RED}Error: File not found: $FILE${NC}" >&2
    exit 1
fi

if [[ ! -f "$SCHEMA_PATH" ]]; then
    echo -e "${RED}Error: Schema not found: $SCHEMA_PATH${NC}" >&2
    exit 1
fi

validate "$FILE"
