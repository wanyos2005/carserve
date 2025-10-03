#!/bin/sh
set -e



echo "Starting Insurance Service..."
exec uvicorn main:app --host 0.0.0.0 --port 8005
