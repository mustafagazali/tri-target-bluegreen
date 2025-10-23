#!/usr/bin/env bash
set -euo pipefail
systemctl enable ec2-web || true
systemctl restart ec2-web