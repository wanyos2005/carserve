import boto3
import os
import re

# --- CONFIG ---
prefix = "/prod"         # e.g. /dev, /staging, /prod
output_file = ".env"

# --- AWS Client ---
ssm = boto3.client("ssm")


def sanitize_key(key: str) -> str:
    """
    Convert any invalid environment variable key into a safe format.
    Only letters, digits, and underscores are allowed.
    """
    key = key.strip()
    key = key.split("/")[-1]  # if key has path-like names
    key = re.sub(r"[^A-Za-z0-9_]", "_", key)  # replace invalid chars
    # Ensure it doesn't start with a digit
    if re.match(r"^[0-9]", key):
        key = f"VAR_{key}"
    return key


def fetch_all_parameters(prefix):
    """Fetch all parameters under a given prefix (handles pagination)."""
    params = {}
    next_token = None

    while True:
        kwargs = {
            "Path": prefix,
            "Recursive": True,
            "WithDecryption": True
        }
        if next_token:
            kwargs["NextToken"] = next_token

        response = ssm.get_parameters_by_path(**kwargs)
        for p in response.get("Parameters", []):
            key = sanitize_key(p["Name"].replace(prefix + "/", ""))
            value = p.get("Value", "")
            if not key or not value:
                print(f"⚠️ Skipping incomplete param: {p['Name']}")
                continue
            params[key] = value

        next_token = response.get("NextToken")
        if not next_token:
            break

    return params


def write_env_file(params):
    """Write parameters to .env, preserving multiline and skipping bad entries."""
    cleaned_params = {}
    for k, v in params.items():
        if not v:
            continue

        # Clean double quotes
        if v.startswith('""') and v.endswith('""'):
            v = v[2:-2]
        elif v.startswith('"') and v.endswith('"'):
            v = v[1:-1]

        v = v.replace("\\n", "\n").strip()

        # Skip malformed key=value pairs
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', k):
            print(f"⚠️ Skipping invalid key: {k}")
            continue

        cleaned_params[k] = v

    # Write to file
    with open(output_file, "w", encoding="utf-8") as f:
        for key, value in cleaned_params.items():
            if "\n" in value:
                f.write(f'{key}="{value.replace(chr(13), "")}"\n')
            else:
                if any(c in value for c in " #&$`'\""):
                    f.write(f'{key}="{value}"\n')
                else:
                    f.write(f"{key}={value}\n")

    print(f"✅ .env file created successfully with {len(cleaned_params)} valid variables.")


def main():
    print(f"📥 Fetching parameters from SSM prefix: {prefix}")
    params = fetch_all_parameters(prefix)
    print(f"🔑 Retrieved {len(params)} parameters.")
    write_env_file(params)


if __name__ == "__main__":
    main()
