#!/usr/bin/env python3
"""
Full deploy script for F1 Tipp Mix.

Usage:
    python deploy.py              # Deploy everything (server + APK + landing)
    python deploy.py --server     # Only deploy server files + restart
    python deploy.py --apk        # Only build + upload APK
    python deploy.py --no-build   # Skip APK build, upload existing APK

Steps:
  1. Build release APK (unless --no-build)
  2. Upload server Python files
  3. Upload version.json
  4. Upload landing page
  5. Upload APK
  6. Restart f1tipp service
  7. Verify service is running
"""

import argparse
import os
import subprocess
import sys
import time

# ── Config ──
VPS_HOST = "76.13.9.45"
VPS_USER = "root"
VPS_PASS = "C)rNJIxeK1.REZ9sdE31"
REMOTE_DIR = "/root/f1-tipp-server"

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
SERVER_DIR = os.path.join(PROJECT_ROOT, "server")
MOBILE_DIR = os.path.join(PROJECT_ROOT, "mobile")
APK_PATH = os.path.join(MOBILE_DIR, "build", "app", "outputs", "flutter-apk", "app-release.apk")

# Server files to deploy
SERVER_FILES = [
    "main.py",
    "config.py",
    "file_server.py",
    "live_service.py",
    "notification_service.py",
    "race_result_worker.py",
    "live_race_relay.py",
]

# Extra files (credentials etc.) - only uploaded if they exist
EXTRA_FILES = [
    "openf1_credentials.json",
]

# Landing page files
LANDING_DIR = os.path.join(SERVER_DIR, "landing")


def connect_ssh():
    import paramiko
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_HOST, username=VPS_USER, password=VPS_PASS)
    return ssh


def build_apk():
    print("\n🔨 Building release APK...")
    result = subprocess.run(
        "flutter build apk --release",
        cwd=MOBILE_DIR,
        capture_output=True, text=True,
        shell=True,
    )
    if result.returncode != 0:
        print(f"❌ APK build failed:\n{result.stderr}")
        sys.exit(1)
    size_mb = os.path.getsize(APK_PATH) / 1024 / 1024
    print(f"✅ APK built: {size_mb:.1f} MB")


def deploy_server_files(ssh):
    print("\n📦 Uploading server files...")
    sftp = ssh.open_sftp()

    for f in SERVER_FILES:
        local = os.path.join(SERVER_DIR, f)
        if os.path.exists(local):
            sftp.put(local, f"{REMOTE_DIR}/{f}")
            print(f"  ✅ {f}")

    for f in EXTRA_FILES:
        local = os.path.join(SERVER_DIR, f)
        if os.path.exists(local):
            sftp.put(local, f"{REMOTE_DIR}/{f}")
            print(f"  ✅ {f} (extra)")

    sftp.close()


def deploy_version_json(ssh):
    print("\n📋 Uploading version.json...")
    sftp = ssh.open_sftp()
    local = os.path.join(PROJECT_ROOT, "version.json")
    sftp.put(local, f"{REMOTE_DIR}/releases/version.json")
    sftp.close()

    import json
    with open(local) as f:
        v = json.load(f)
    print(f"  ✅ v{v['version']} build {v['build']}")


def deploy_landing(ssh):
    print("\n🌐 Uploading landing page...")
    sftp = ssh.open_sftp()

    # Ensure remote landing dir exists
    try:
        sftp.stat(f"{REMOTE_DIR}/landing")
    except FileNotFoundError:
        sftp.mkdir(f"{REMOTE_DIR}/landing")

    count = 0
    for f in os.listdir(LANDING_DIR):
        local = os.path.join(LANDING_DIR, f)
        if os.path.isfile(local):
            sftp.put(local, f"{REMOTE_DIR}/landing/{f}")
            count += 1

    sftp.close()
    print(f"  ✅ {count} files uploaded")


def deploy_apk(ssh):
    print("\n📱 Uploading APK...")
    if not os.path.exists(APK_PATH):
        print("  ❌ APK not found! Run with --build or build first.")
        return

    sftp = ssh.open_sftp()

    # Ensure releases dir exists
    try:
        sftp.stat(f"{REMOTE_DIR}/releases")
    except FileNotFoundError:
        sftp.mkdir(f"{REMOTE_DIR}/releases")

    size_mb = os.path.getsize(APK_PATH) / 1024 / 1024
    print(f"  Uploading {size_mb:.1f} MB...")
    sftp.put(APK_PATH, f"{REMOTE_DIR}/releases/f1tippmix.apk")
    sftp.close()
    print(f"  ✅ APK uploaded")


def restart_service(ssh):
    print("\n🔄 Restarting f1tipp service...")
    _, o, e = ssh.exec_command("systemctl restart f1tipp")
    o.read()
    time.sleep(3)

    # Verify
    _, o, _ = ssh.exec_command("systemctl is-active f1tipp")
    status = o.read().decode().strip()
    if status == "active":
        print(f"  ✅ Service is {status}")
    else:
        print(f"  ⚠️  Service status: {status}")

    # Show recent logs
    _, o, _ = ssh.exec_command(
        'journalctl -u f1tipp --since "10 sec ago" --no-pager -l 2>&1 | grep -i "started\\|enabled\\|error" | head -10'
    )
    logs = o.read().decode().strip()
    if logs:
        print(f"  Logs:\n{logs}")


def main():
    parser = argparse.ArgumentParser(description="Deploy F1 Tipp Mix to VPS")
    parser.add_argument("--server", action="store_true", help="Only deploy server files")
    parser.add_argument("--apk", action="store_true", help="Only build + upload APK")
    parser.add_argument("--no-build", action="store_true", help="Skip APK build")
    args = parser.parse_args()

    deploy_all = not args.server and not args.apk

    # Build APK
    if (deploy_all or args.apk) and not args.no_build:
        build_apk()

    # Connect to VPS
    print(f"\n🔗 Connecting to {VPS_HOST}...")
    ssh = connect_ssh()
    print("  ✅ Connected")

    try:
        if deploy_all or args.server:
            deploy_server_files(ssh)

        if deploy_all:
            deploy_version_json(ssh)
            deploy_landing(ssh)

        if deploy_all or args.apk:
            deploy_apk(ssh)

        # Always restart service
        restart_service(ssh)

    finally:
        ssh.close()

    print("\n🎉 Deploy complete!")


if __name__ == "__main__":
    main()
