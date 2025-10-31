import boto3
import os
import re

prefix = "/prod"         # e.g. /dev, /staging, /prod
output_file = ".env"

ssm = boto3.client("ssm")


def sanitize_key(key: str) -> str:
    """Convert invalid environment variable names to safe format."""
    key = key.strip().split("/")[-1]
    key = re.sub(r"[^A-Za-z0-9_]", "_", key)
    if re.match(r"^[0-9]", key):
        key = f"VAR_{key}"
    return key


def fetch_all_parameters(prefix):
    """Fetch all SSM params recursively."""
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
    """Ensure the key and value form a valid KEY=value line for Docker."""
    if not key or not value:
        return False
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
        return False
    if "\n" in key or "=" in key:
        return False
    return True


def write_env_file(params):
    cleaned_params = {}
    for k, v in params.items():
        # Clean quotes
        if v.startswith('""') and v.endswith('""'):
            v = v[2:-2]
        elif v.startswith('"') and v.endswith('"'):
            v = v[1:-1]

        v = v.replace("\\n", "\n").strip()

        # Skip any malformed pairs
        if not is_valid_env_pair(k, v):
            print(f"⚠️ Skipping malformed variable: {k}={v[:10]}...")
            continue

        cleaned_params[k] = v

    with open(output_file, "w", encoding="utf-8") as f:
        for key, value in cleaned_params.items():
            if "\n" in value:
                f.write(f'{key}="{value.replace(chr(13), "")}"\n')
            elif any(c in value for c in " #&$`'\""):
                f.write(f'{key}="{value}"\n')
            else:
                f.write(f"{key}={value}\n")

    print(f"✅ .env file created successfully with {len(cleaned_params)} valid variables.")


def main():
    print(f"📥 Fetching parameters from SSM prefix: {prefix}")
    params = fetch_all_parameters(prefix)
    print(f"🔑 Retrieved {len(params)} parameters total.")
    write_env_file(params)


if __name__ == "__main__":
    main()
