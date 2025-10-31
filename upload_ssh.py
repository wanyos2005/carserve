import boto3
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

# --- CONFIG ---
prefix = "/prod"
env_file = ".env1"
param_type = "SecureString"
max_workers = 5
retry_attempts = 3
retry_delay = 1

ssm = boto3.client("ssm")

def load_envs(file_path):
    """Parse .env safely, supporting multi-line RSA/FCM keys."""
    envs = {}
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    key = None
    buffer = []
    in_multiline_block = False

    for line in lines:
        if not line.strip() or line.strip().startswith("#"):
            continue

        # Begin new key=value
        if not in_multiline_block and "=" in line:
            if key and buffer:
                envs[key] = "\n".join(buffer).strip()
                buffer = []

            key, value = line.split("=", 1)
            key, value = key.strip(), value.strip()

            # skip empty values safely
            if value == "":
                continue

            # handle literal \n escape sequences (FCM_PRIVATE_KEY)
            if "\\n" in value and not value.startswith("-----BEGIN"):
                value = value.replace("\\n", "\n")

            # detect multiline private key blocks
            if value.startswith("-----BEGIN"):
                in_multiline_block = True
                buffer.append(value)
            else:
                envs[key] = value
                key = None
        elif in_multiline_block:
            buffer.append(line)
            if "-----END" in line:
                envs[key] = "\n".join(buffer).strip()
                buffer = []
                in_multiline_block = False
                key = None

    # Add final buffered value
    if key and buffer:
        envs[key] = "\n".join(buffer).strip()

    return envs

def upload_param(name, value):
    """Uploads one parameter to SSM with retry logic."""
    for attempt in range(1, retry_attempts + 1):
        try:
            kwargs = {
                "Name": f"{prefix}/{name}",
                "Value": value,
                "Type": param_type,
                "Overwrite": True,
            }

            # If value is too long, use Advanced tier
            if len(value) > 4096:
                kwargs["Tier"] = "Advanced"

            ssm.put_parameter(**kwargs)
            time.sleep(0.2)
            return f"✅ Uploaded {prefix}/{name}"
        except ssm.exceptions.ThrottlingException:
            if attempt < retry_attempts:
                time.sleep(retry_delay)
            else:
                return f"❌ Failed {prefix}/{name}: Throttled (max retries)"
        except Exception as e:
            return f"❌ Failed {prefix}/{name}: {e}"


def main():
    envs = load_envs(env_file)
    print(f"📦 Found {len(envs)} environment variables to upload...")

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(upload_param, k, v): k for k, v in envs.items()}
        for future in as_completed(futures):
            print(future.result())

    print("🎉 All uploads completed.")


if __name__ == "__main__":
    main()
