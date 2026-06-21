#!/usr/bin/env python3
import os
import sys
import json
import urllib.request
import urllib.error

ELASTIC_URL = os.environ.get("ELASTIC_URL", "https://10.10.0.50:9200")
ELASTIC_API_KEY = os.environ.get("ELASTIC_API_KEY", "")
COMPILED_DIR = "detections/compiled-rules"

if not ELASTIC_API_KEY:
    print("[WARNING] ELASTIC_API_KEY environment variable is empty. Deploy dry-run active.")

def deploy_rule(rule_file):
    with open(os.path.join(COMPILED_DIR, rule_file), 'r') as f:
        rule_data = json.load(f)
        
    print(f"Deploying rule: {rule_data['name']}")
    
    if not ELASTIC_API_KEY:
        print(f"  [DRY-RUN] Rule {rule_data['name']} (ID: {rule_data['rule_id']}) ready for API POST")
        return
        
    url = f"{ELASTIC_URL}/api/detection_engine/rules"
    headers = {
        "Authorization": f"ApiKey {ELASTIC_API_KEY}",
        "Content-Type": "application/json",
        "kbn-xsrf": "true"
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(rule_data).encode("utf-8"),
        headers=headers,
        method="POST"
    )
    
    try:
        # Ignore SSL verification for self-signed development certificates
        import ssl
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        
        with urllib.request.urlopen(req, context=ctx) as response:
            res = json.loads(response.read().decode())
            print(f"  [SUCCESS] Rule deployed successfully. Rule ID: {res.get('id')}")
    except urllib.error.HTTPError as e:
        # Check if rule already exists (409 Conflict)
        if e.code == 409:
            print("  [INFO] Rule already exists. Attempting update...")
            # Run PUT update logic here
        else:
            print(f"  [ERROR] Failed to deploy rule. Status: {e.code}, Reason: {e.read().decode()}")
    except Exception as e:
        print(f"  [ERROR] Connection error: {e}")

if os.path.exists(COMPILED_DIR):
    files = [f for f in os.listdir(COMPILED_DIR) if f.endswith(".json")]
    for file in files:
        deploy_rule(file)
else:
    print(f"[ERROR] Compiled rules directory {COMPILED_DIR} not found. Run compiler first.")
