#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

./build.sh

version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
build_number=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Info.plist)
release_dir="site/downloads/v${version}"
mkdir -p "$release_dir"
cp build/RbxMulti.zip "$release_dir/RbxMulti.zip"
(cd "$release_dir" && shasum -a 256 RbxMulti.zip > SHA256SUMS.txt)

signature=$(build/sparkle/bin/sign_update -p "$release_dir/RbxMulti.zip")
length=$(stat -f '%z' "$release_dir/RbxMulti.zip")
pub_date=$(date -Ru)
feed="site/appcast.xml"
sparkle_signer=build/sparkle/bin/sign_update

python3 - "$feed" "$version" "$build_number" "$signature" "$length" "$pub_date" <<'PY'
from pathlib import Path
import sys
import re

feed, version, build, signature, length, pub_date = sys.argv[1:]
path = Path(feed)
xml = path.read_text()
import re
xml = re.sub(r"\s*<!-- sparkle-signatures:.*?-->", "", xml, flags=re.DOTALL)
version_tag = f"<sparkle:shortVersionString>{version}</sparkle:shortVersionString>"
item_pattern = re.compile(r"\s*<item>(?:(?!</item>).)*" + re.escape(version_tag) + r"(?:(?!</item>).)*</item>", re.DOTALL)
xml = item_pattern.sub("", xml)

item = f'''    <item>
      <title>RbxMulti {version}</title>
      <link>https://rlken.github.io/RbxMulti/#download</link>
      <sparkle:version>{build}</sparkle:version>
      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/rlken/RbxMulti/blob/main/CHANGELOG.md</sparkle:releaseNotesLink>
      <pubDate>{pub_date}</pubDate>
      <enclosure url="https://rlken.github.io/RbxMulti/downloads/v{version}/RbxMulti.zip" length="{length}" type="application/octet-stream" sparkle:edSignature="{signature}" />
    </item>
'''
marker = "    <item>" if "    <item>" in xml else "  </channel>"
if marker not in xml:
    raise SystemExit(f"{feed} has no channel insertion point")
xml = xml.replace(marker, item + marker, 1)
path.write_text(xml)
PY

"$sparkle_signer" --disable-signing-warning "$feed"
"$sparkle_signer" --verify "$feed"

echo "Prepared signed website update ${version} (build ${build_number})."
echo "Review and commit site/downloads/v${version}/ and site/appcast.xml to publish it."
