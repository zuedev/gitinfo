<#
.SYNOPSIS
    Validates .gitinfo files against the gitinfo JSON Schema.

.DESCRIPTION
    A PowerShell validator for .gitinfo files. Parses JSONC (strips comments)
    and validates against the schema.

.PARAMETER Path
    Path to the .gitinfo file. Defaults to ".gitinfo" in the current directory.

.EXAMPLE
    .\Validate-GitInfo.ps1
    Validates .gitinfo in the current directory.

.EXAMPLE
    .\Validate-GitInfo.ps1 -Path "path/to/.gitinfo"
    Validates a specific .gitinfo file.
#>

param(
    [Parameter(Position = 0)]
    [string]$Path = ".gitinfo"
)

$ErrorActionPreference = "Stop"

# Schema path (two levels up from validators/powershell/)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SchemaPath = Join-Path $ScriptDir "..\..\gitinfo.schema.json"

function Remove-JsonComments {
    param([string]$Jsonc)
    
    $result = New-Object System.Text.StringBuilder
    $i = 0
    $inString = $false
    $stringChar = $null
    
    while ($i -lt $Jsonc.Length) {
        $char = $Jsonc[$i]
        $next = if ($i + 1 -lt $Jsonc.Length) { $Jsonc[$i + 1] } else { $null }
        
        # Track string state
        if (-not $inString -and ($char -eq '"' -or $char -eq "'")) {
            $inString = $true
            $stringChar = $char
            [void]$result.Append($char)
            $i++
            continue
        }
        
        if ($inString) {
            if ($char -eq '\' -and $i + 1 -lt $Jsonc.Length) {
                [void]$result.Append($char)
                [void]$result.Append($Jsonc[$i + 1])
                $i += 2
                continue
            }
            if ($char -eq $stringChar) {
                $inString = $false
                $stringChar = $null
            }
            [void]$result.Append($char)
            $i++
            continue
        }
        
        # Single-line comment
        if ($char -eq '/' -and $next -eq '/') {
            while ($i -lt $Jsonc.Length -and $Jsonc[$i] -ne "`n") {
                $i++
            }
            continue
        }
        
        # Multi-line comment
        if ($char -eq '/' -and $next -eq '*') {
            $i += 2
            while ($i -lt $Jsonc.Length - 1 -and -not ($Jsonc[$i] -eq '*' -and $Jsonc[$i + 1] -eq '/')) {
                $i++
            }
            $i += 2
            continue
        }
        
        [void]$result.Append($char)
        $i++
    }
    
    return $result.ToString()
}

function Test-Uri {
    param([string]$Value)
    try {
        $uri = [System.Uri]::new($Value)
        return $uri.Scheme -eq "http" -or $uri.Scheme -eq "https"
    }
    catch {
        return $false
    }
}

function Test-Email {
    param([string]$Value)
    return $Value -match '^[^\s@]+@[^\s@]+\.[^\s@]+$'
}

function Test-Schema {
    param(
        $Data,
        $Schema,
        [string]$JsonPath = ""
    )
    
    $errors = @()
    
    if ($Schema.type -eq "object") {
        if ($Data -isnot [System.Collections.IDictionary] -and $Data.GetType().Name -ne "PSCustomObject") {
            $errors += "$(if ($JsonPath) { $JsonPath } else { 'root' }): expected object"
            return $errors
        }
        
        # Convert PSCustomObject to hashtable for easier handling
        $dataHash = @{}
        $Data.PSObject.Properties | ForEach-Object { $dataHash[$_.Name] = $_.Value }
        
        # Check additionalProperties
        if ($Schema.additionalProperties -eq $false -and $Schema.properties) {
            $allowed = $Schema.properties.PSObject.Properties.Name
            foreach ($key in $dataHash.Keys) {
                if ($key -notin $allowed) {
                    $errors += "$(if ($JsonPath) { $JsonPath } else { 'root' }): unknown property `"$key`""
                }
            }
        }
        
        # Validate each property
        if ($Schema.properties) {
            foreach ($prop in $Schema.properties.PSObject.Properties) {
                $key = $prop.Name
                $propSchema = $prop.Value
                if ($dataHash.ContainsKey($key)) {
                    $errors += Test-Schema -Data $dataHash[$key] -Schema $propSchema -JsonPath "$JsonPath.$key"
                }
            }
        }
    }
    elseif ($Schema.type -eq "array") {
        if ($Data -isnot [System.Array]) {
            $errors += "${JsonPath}: expected array"
            return $errors
        }
        
        if ($Schema.items) {
            for ($i = 0; $i -lt $Data.Count; $i++) {
                $itemSchema = if ($Schema.items -is [System.Array]) { $Schema.items[$i] } else { $Schema.items }
                if ($itemSchema) {
                    $errors += Test-Schema -Data $Data[$i] -Schema $itemSchema -JsonPath "$JsonPath[$i]"
                }
            }
            
            if ($Schema.minItems -and $Data.Count -lt $Schema.minItems) {
                $errors += "${JsonPath}: expected at least $($Schema.minItems) items"
            }
            if ($Schema.maxItems -and $Data.Count -gt $Schema.maxItems) {
                $errors += "${JsonPath}: expected at most $($Schema.maxItems) items"
            }
        }
    }
    elseif ($Schema.type -eq "string") {
        if ($Data -isnot [string]) {
            $errors += "${JsonPath}: expected string"
            return $errors
        }
        
        if ($Schema.minLength -and $Data.Length -lt $Schema.minLength) {
            $errors += "${JsonPath}: string too short (min $($Schema.minLength))"
        }
        
        if ($Schema.format -eq "uri") {
            if (-not (Test-Uri $Data)) {
                $errors += "${JsonPath}: invalid URI `"$Data`""
            }
        }
        
        if ($Schema.format -eq "email") {
            if (-not (Test-Email $Data)) {
                $errors += "${JsonPath}: invalid email `"$Data`""
            }
        }
        
        if ($Schema.pattern) {
            if ($Data -notmatch $Schema.pattern) {
                $errors += "${JsonPath}: does not match pattern $($Schema.pattern)"
            }
        }
    }
    
    return $errors
}

# Main
if (-not (Test-Path $Path)) {
    Write-Error "Error: File not found: $Path"
    exit 1
}

if (-not (Test-Path $SchemaPath)) {
    Write-Error "Error: Schema not found: $SchemaPath"
    exit 1
}

# Read and parse schema
try {
    $schemaContent = Get-Content -Path $SchemaPath -Raw
    $schema = $schemaContent | ConvertFrom-Json
}
catch {
    Write-Error "Error parsing schema: $_"
    exit 1
}

# Read and parse .gitinfo file
try {
    $content = Get-Content -Path $Path -Raw
    $stripped = Remove-JsonComments -Jsonc $content
    $data = $stripped | ConvertFrom-Json
}
catch {
    Write-Error "Error parsing JSONC: $_"
    exit 1
}

# Validate against schema
$errors = Test-Schema -Data $data -Schema $schema

if ($errors.Count -gt 0) {
    Write-Host "Validation failed for ${Path}:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
    exit 1
}

Write-Host "✓ $Path is valid" -ForegroundColor Green
exit 0
