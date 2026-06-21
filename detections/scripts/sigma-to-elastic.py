#!/usr/bin/env python3
import os
import sys
import yaml
import json

RULE_DIR = "detections/sigma-rules"
OUTPUT_DIR = "detections/compiled-rules"

os.makedirs(OUTPUT_DIR, exist_ok=True)

def compile_rule(rule_path):
    with open(rule_path, 'r') as f:
        rule = yaml.safe_load(f)
    
    title = rule["title"]
    description = rule["description"]
    rule_id = rule["id"]
    level = rule["level"]
    
    # Simple mapping logic for demonstration of automated compilation
    query_parts = []
    
    # Identify index/logsource mapping
    logsource = rule.get("logsource", {})
    product = logsource.get("product", "windows")
    service = logsource.get("service", "security")
    
    index_pattern = "logs-*"
    if product == "windows":
        index_pattern = "winlogbeat-*,logs-windows*"
    elif product == "linux":
        index_pattern = "auditbeat-*,logs-system*"
        
    detection = rule.get("detection", {})
    
    # Parse standard simple selection condition
    for name, selection in detection.items():
        if name == "condition":
            continue
        if not isinstance(selection, dict):
            continue
            
        for field, value in selection.items():
            clean_field = field.split("|")[0]
            modifier = field.split("|")[1] if "|" in field else None
            
            # Map common event fields to ECS (Elastic Common Schema)
            if clean_field == "EventID":
                clean_field = "winlog.event_id"
            elif clean_field == "CommandLine":
                clean_field = "process.command_line"
            elif clean_field == "TicketEncryptionType":
                clean_field = "winlog.event_data.TicketEncryptionType"
            elif clean_field == "TicketTicketLifetime":
                clean_field = "winlog.event_data.TicketTicketLifetime"
                
            if isinstance(value, list):
                val_strs = []
                for val in value:
                    if modifier == "contains":
                        val_strs.append(f'{clean_field}: *{val}*')
                    else:
                        val_strs.append(f'{clean_field}: "{val}"')
                query_parts.append("(" + " OR ".join(val_strs) + ")")
            else:
                if modifier == "contains":
                    query_parts.append(f'{clean_field}: *{value}*')
                else:
                    query_parts.append(f'{clean_field}: "{value}"')
                    
    kql_query = " AND ".join(query_parts)
    
    # Construct Elastic Alert Rule schema
    elastic_rule = {
        "rule_id": rule_id,
        "name": title,
        "description": description,
        "type": "query",
        "query": kql_query,
        "language": "kuery",
        "index": [index_pattern],
        "severity": level,
        "risk_score": 50 if level == "medium" else 85,
        "enabled": True,
        "interval": "5m",
        "from": "now-6m",
        "to": "now"
    }
    
    output_path = os.path.join(OUTPUT_DIR, f"{rule_id}.json")
    with open(output_path, 'w') as out_f:
        json.dump(elastic_rule, out_f, indent=2)
        
    print(f"Compiled: {title} -> {output_path}")

print("=== Compiling Sigma Rules to Elastic KQL ===")
for root, _, files in os.walk(RULE_DIR):
    for file in files:
        if file.endswith(".yml") or file.endswith(".yaml"):
            compile_rule(os.path.join(root, file))
print("=== Compilation Completed ===")
