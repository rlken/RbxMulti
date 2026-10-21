#!/bin/bash
set -e
APP=build/RbxMulti.app
rm -rf build
mkdir -p $APP/Contents/MacOS $APP/Contents/Resources build/icon.iconset
for arch in arm64 x86_64; do
  swiftc -parse-as-library -O -target $arch-apple-macos13.0 \
    Sources/*.swift -o build/RbxMulti-$arch
done
lipo -create build/RbxMulti-arm64 build/RbxMulti-x86_64 -output $APP/Contents/MacOS/RbxMulti
for s in 16 32 128 256 512; do
  sips -z $s $s Resources/icon_1024.png --out build/icon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) Resources/icon_1024.png --out build/icon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns build/icon.iconset -o $APP/Contents/Resources/AppIcon.icns
cp Info.plist $APP/Contents/Info.plist
codesign --force --deep --sign - $APP
(cd build && ditto -c -k --keepParent RbxMulti.app RbxMulti.zip)
echo "Built build/RbxMulti.zip"
