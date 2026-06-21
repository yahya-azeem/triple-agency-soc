#!/usr/bin/env python3
import os
import sys
import yaml

REQUIRED_KEYS = ["title", "id", "description", "logsource", "detection", "level", "tags"]
RULE_DIR = "detections/sigma-rules"

print("=== Starting Sigma Rule Linting ===")
errors = 0

for root, _, files in os.walk(RULE_DIR):
    for file in files:
        if file.endswith(".yml") or file.endswith(".yaml"):
            file_path = os.path.join(root, file)
            print(f"Linting: {file_path}")
            try:
                with open(file_path, 'r') as f:
                    rule = yaml.safe_load(f)
                
                # Check for required keys
                for key in REQUIRED_KEYS:
                    if key not in rule:
                        print(f"  [ERROR] Missing required key: '{key}'")
                        errors += 1
                        
                # Check tags format
                if "tags" in rule and not isinstance(rule["tags"], list):
                    print("  [ERROR] 'tags' must be a list")
                    errors += 1

            except Exception as e:
                print(f"  [ERROR] Failed to parse YAML: {e}")
                errors += 1

if errors > 0:
    print(f"=== Linting Failed: {errors} errors found ===")
    sys.exit(1)
else:
    print("=== Linting Passed successfully ===")
    sys.exit(0)
