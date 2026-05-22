---
name: update-aws-secret
description: Use when adding or updating a key in an AWS Secrets Manager secret that contains a YAML file. Always downloads existing content first before modifying to prevent data loss.
---

# Update AWS Secret

## Overview

Safely append or update a key in an AWS Secrets Manager YAML secret.
**Core principle:** Always download first, append, diff, confirm, push, verify, cleanup.

Never push a secret file that wasn't built from the downloaded version — this would destroy all existing keys.

## Process

### 1. Refresh AWS SSO

Ask the user to run the login command for the relevant profile before proceeding:

```bash
aws sso login --profile AWSAdministratorAccess-{account}
```

Wait for confirmation that login succeeded before continuing.

### 2. Gather Inputs

Use `AskUserQuestion` to collect all four required values before doing anything:

- **AWS account number** (e.g. `266735823956` for dev, `565393042914` for staging)
- **Environment** (e.g. `dev`, `staging`)
- **Secret key name** (e.g. `POLICY_EXTRACTION_EMBEDDING_API_KEY`)
- **Secret value** (the actual value to set)

Derive from account + env:
```
profile   = AWSAdministratorAccess-{account}
secret_id = vijil/{env}/vijil-console-helm-secrets
```

### 2. Download Existing Secret

```bash
export AWS_PROFILE=AWSAdministratorAccess-{account}
aws secretsmanager get-secret-value \
  --region us-west-2 \
  --secret-id vijil/{env}/vijil-console-helm-secrets \
  --query SecretString --output text > /tmp/secrets-current.yaml
```

### 3. Append the New Key

Use Python to safely parse and modify — avoids YAML indentation mistakes:

```bash
python3 -c "
import yaml
with open('/tmp/secrets-current.yaml') as f:
    data = yaml.safe_load(f)
data['secrets']['vijil-console']['{KEY_NAME}'] = '{KEY_VALUE}'
with open('/tmp/secrets-updated.yaml', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
"
```

Note: `yaml.dump` may reorder keys alphabetically — this is cosmetically different but functionally harmless.

### 4. Diff and Confirm

```bash
diff /tmp/secrets-current.yaml /tmp/secrets-updated.yaml
```

Show the diff to the user and ask for explicit confirmation before pushing. Do not push without confirmation.

### 5. Push

```bash
aws secretsmanager put-secret-value \
  --region us-west-2 \
  --secret-id vijil/{env}/vijil-console-helm-secrets \
  --secret-string file:///tmp/secrets-updated.yaml
```

### 6. Verify

Read the secret back and confirm the new key is present:

```bash
aws secretsmanager get-secret-value \
  --region us-west-2 \
  --secret-id vijil/{env}/vijil-console-helm-secrets \
  --query SecretString --output text
```

### 7. Cleanup

```bash
rm /tmp/secrets-current.yaml /tmp/secrets-updated.yaml
```

These files contain plaintext secrets — always delete immediately after verifying.

## Key Rules

- **Never skip the download step** — pushing without downloading destroys all existing keys
- **Always diff before pushing** — confirm only the intended change is present
- **Always confirm with user** before executing the push
- **Always clean up** temp files — they contain plaintext secrets
- If `secrets.vijil-console` doesn't exist in the downloaded file, stop and report — the structure is unexpected

## Known Environments

| Environment | Account | Profile | Secret ID |
|---|---|---|---|
| Dev | 266735823956 | AWSAdministratorAccess-266735823956 | vijil/dev/vijil-console-helm-secrets |
| Staging | 565393042914 | AWSAdministratorAccess-565393042914 | vijil/staging/vijil-console-helm-secrets |