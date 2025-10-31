import boto3
import re

# -----------------------------
# Configuration
# -----------------------------
prefix = "/prod"
output_file = ".env"

ssm = boto3.client("ssm")

# Known bad line to remove if needed
BAD_LINE_PATTERN = re.compile(
    r"^M1J2eEhWuw360DBh7F_Z14/8KNUAEaVwzTk39E_P1z4ZINNaWA9_5w=="
)

# -----------------------------
# Helper Functions
# -----------------------------
def sanitize_key(key: str) -> str:
    """Ensure valid env key name for .env files."""
    key = key.strip().split("/")[-1]
    key = re.sub(r"[^A-Za-z0-9_]", "_", key)
    if re.match(r"^[0-9]", key):
        key = f"VAR_{key}"
    return key


def fetch_all_parameters(prefix):
    """Fetch all parameters recursively from SSM."""
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
            if not key or value is None:
                print(f"⚠️ Skipping incomplete param: {p['Name']}")
                continue
            params[key] = value

        next_token = response.get("NextToken")
        if not next_token:
            break

    return params


def is_valid_env_pair(key, value):
    """Check if key/value is valid for .env."""
    if not key or not value:
        return False
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
        return False
    if "\n" in key or "=" in key:
        return False
    return True


def write_env_file(params):
    """Write cleaned parameters to .env with Docker Compose-safe escaping."""
    cleaned_params = {}

    for k, v in params.items():
        # Remove extra quotes
        if v.startswith('""') and v.endswith('""'):
            v = v[2:-2]
        elif v.startswith('"') and v.endswith('"'):
            v = v[1:-1]

        # Convert literal \n to actual newline
        v = v.replace("\\n", "\n").strip()

        # Skip malformed keys
        if not is_valid_env_pair(k, v):
            print(f"⚠️ Skipping malformed variable: {k}={v[:10]}...")
            continue

        cleaned_params[k] = v

    # Write initial .env file
    with open(output_file, "w", encoding="utf-8") as f:
        for key, value in cleaned_params.items():
            # Escape $ for Docker Compose
            value = value.replace("$", "$$")

            # Handle multiline or special chars
            if "\n" in value:
                value = value.replace("\n", "\\n")  # keep Docker Compose safe
                f.write(f'{key}="{value}"\n')
            elif any(c in value for c in ' #&"\''):
                f.write(f'{key}="{value}"\n')
            else:
                f.write(f"{key}={value}\n")

    # Remove known bad lines
    with open(output_file, "r", encoding="utf-8") as f:
        lines = f.readlines()
    filtered_lines = [ln for ln in lines if not BAD_LINE_PATTERN.match(ln.strip())]

    if len(filtered_lines) != len(lines):
        print(f"🧹 Removed {len(lines) - len(filtered_lines)} bad line(s) from .env")

    with open(output_file, "w", encoding="utf-8") as f:
        f.writelines(filtered_lines)

    print(f"✅ .env file finalized successfully with {len(filtered_lines)} clean variables.")


# -----------------------------
# Main
# -----------------------------
def main():
    print(f"📥 Fetching parameters from SSM prefix: {prefix}")
    params = fetch_all_parameters(prefix)
    print(f"🔑 Retrieved {len(params)} parameters total.")
    write_env_file(params)


if __name__ == "__main__":
    main()
