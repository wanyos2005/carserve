#!/bin/sh
set -e



echo "Starting user Service..."
exec uvicorn main:app --host 0.0.0.0 --port 8001
