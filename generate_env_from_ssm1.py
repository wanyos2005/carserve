import boto3
import os
import re   # 👈 add this import

# --- CONFIG ---
prefix = "/prod"         # e.g. /dev, /staging, /prod
output_file = ".env"

# --- AWS Client ---
ssm = boto3.client("ssm")

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
            key = p["Name"].replace(prefix + "/", "")
            value = p["Value"]
            params[key] = value

        next_token = response.get("NextToken")
        if not next_token:
            break

    return params


def write_env_file(params):
    """Write parameters to .env, preserving multiline and removing double quotes correctly."""
    cleaned_params = {}
    for k, v in params.items():
        if not v:
            continue

        # Remove wrapping double quotes if they exist
        if v.startswith('""') and v.endswith('""'):
            v = v[2:-2]

        # Also handle cases like "value" or ""value""
        if v.startswith('"') and v.endswith('"'):
            v = v[1:-1]

        # Unescape any embedded \n sequences properly
        v = v.replace("\\n", "\n").strip()

        cleaned_params[k] = v

    with open(output_file, "w", encoding="utf-8") as f:
        for key, value in cleaned_params.items():
            if "\n" in value:
                # Preserve real multiline blocks (like PEM keys)
                f.write(f'{key}="{value.replace(chr(13), "")}"\n')
            else:
                # Quote if it has spaces or special characters
                if any(c in value for c in " #&$`'\""):
                    f.write(f'{key}="{value}"\n')
                else:
                    f.write(f"{key}={value}\n")

    print(f"✅ .env file created successfully with {len(cleaned_params)} variables.")


def main():
    print(f"📥 Fetching parameters from SSM prefix: {prefix}")
    params = fetch_all_parameters(prefix)
    print(f"🔑 Retrieved {len(params)} parameters.")
    write_env_file(params)


if __name__ == "__main__":
    main()
