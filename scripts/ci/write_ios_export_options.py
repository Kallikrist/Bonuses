#!/usr/bin/env python3
"""Write an App Store ExportOptions.plist for CI. No secrets in the file."""

from __future__ import annotations

import argparse
import plistlib
from pathlib import Path

BUNDLE_ID = "com.bonuses.app.bonuses"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--team-id", required=True)
    parser.add_argument("--profile-name", required=True)
    args = parser.parse_args()

    data = {
        "method": "app-store",
        "teamID": args.team_id,
        "signingStyle": "manual",
        "signingCertificate": "iPhone Distribution",
        "compileBitcode": False,
        "stripSwiftSymbols": True,
        "uploadSymbols": True,
        "provisioningProfiles": {BUNDLE_ID: args.profile_name},
    }
    path = Path(args.output)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        plistlib.dump(data, handle)


if __name__ == "__main__":
    main()
