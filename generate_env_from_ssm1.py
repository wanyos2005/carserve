import boto3
import re

prefix = "/prod"
output_file = ".env"

ssm = boto3.client("ssm")

# The known bad pattern (adjust if needed)
BAD_LINE_PATTERN = re.compile(r"^M1J2eEhWuw360DBh7F_Z14/8KNUAEaVwzTk39E_P1z4ZINNaWA9_5w==")

def sanitize_key(key: str) -> str:
    """Ensure valid env key name."""
    key = key.strip().split("/")[-1]
    key = re.sub(r"[^A-Za-z0-9_]", "_", key)
    if re.match(r"^[0-9]", key):
        key = f"VAR_{key}"
    return key


def fetch_all_parameters(prefix):
    params = {}
    next_token = None

    while True:
        kwargs = {"Path": prefix, "Recursive": True, "WithDecryption": True}
        if next_token:
            kwargs["NextToken"] = next_token

        response = ssm.get_parameters_by_path(**kwargs)
        for p in response.get("Parameters", []):
            key = sanitize_key(p["Name"].replace(prefix + "/", ""))
            value = p.get("Value", "").strip()
            if not key or not value:
                print(f"⚠️ Skipping incomplete param: {p['Name']}")
                continue
            params[key] = value

        next_token = response.get("NextToken")
        if not next_token:
            break

    return params


def is_valid_env_pair(key, value):
    if not key or not value:
        return False
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
        return False
    if "\n" in key or "=" in key:
        return False
    return True

import boto3
import re

prefix = "/prod"
output_file = ".env"

ssm = boto3.client("ssm")

# Known bad lines (exact match, can add more if needed)
BAD_LINE_PATTERN = re.compile(r"^M1J2eEhWuw360DBh7F_Z14/8KNUAEaVwzTk39E_P1z4ZINNaWA9_5w==$")

def sanitize_key(key: str) -> str:
    """Ensure valid env key name."""
    key = key.strip().split("/")[-1]
    key = re.sub(r"[^A-Za-z0-9_]", "_", key)
    if re.match(r"^[0-9]", key):
        key = f"VAR_{key}"
    return key

def fetch_all_parameters(prefix):
    params = {}
    next_token = None

    while True:
        kwargs = {"Path": prefix, "Recursive": True, "WithDecryption": True}
        if next_token:
            kwargs["NextToken"] = next_token

        response = ssm.get_parameters_by_path(**kwargs)
        for p in response.get("Parameters", []):
            key = sanitize_key(p["Name"].replace(prefix + "/", ""))
            value = p.get("Value", "").strip()
            if not key or not value:
                print(f"⚠️ Skipping incomplete param: {p['Name']}")
                continue
            params[key] = value

        next_token = response.get("NextToken")
        if not next_token:
            break

    return params

def is_valid_env_pair(key, value):
    if not key or not value:
        return False
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
        return False
    return True

def write_env_file(params):
    cleaned_params = {}

    for k, v in params.items():
        if v.startswith('""') and v.endswith('""'):
            v = v[2:-2]
        elif v.startswith('"') and v.endswith('"'):
            v = v[1:-1]

        v = v.strip()

        if not is_valid_env_pair(k, v):
            print(f"⚠️ Skipping malformed variable: {k}={v[:10]}...")
            continue

        cleaned_params[k] = v

    with open(output_file, "w", encoding="utf-8") as f:
        for key, value in cleaned_params.items():
            # Handle multiline values
            if "\n" in value:
                value = value.replace("\n", "\\n")  # convert to literal \n
            value = value.replace("$", "$$")        # escape $ for Docker Compose
            # Wrap values with special characters in quotes
            if any(c in value for c in ' #&$"\''):
                f.write(f'{key}="{value}"\n')
            else:
                f.write(f"{key}={value}\n")

    # Remove known bad lines
    with open(output_file, "r", encoding="utf-8") as f:
        lines = f.readlines()
    filtered_lines = [ln for ln in lines if not BAD_LINE_PATTERN.match(ln.strip())]
    with open(output_file, "w", encoding="utf-8") as f:
        f.writelines(filtered_lines)

    print(f"✅ .env file finalized with {len(filtered_lines)} clean variables.")


def main():
    print(f"📥 Fetching parameters from SSM prefix: {prefix}")
    params = fetch_all_parameters(prefix)
    print(f"🔑 Retrieved {len(params)} parameters total.")
    write_env_file(params)


if __name__ == "__main__":
    main()
