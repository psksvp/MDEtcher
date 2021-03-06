import Foundation

let buildNoFile = URL(fileURLWithPath: "./buildNo.txt")
let buildNumber = try! String(contentsOf: buildNoFile, encoding: .utf8)
let plist = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>markdown</string>
			</array>
			<key>CFBundleTypeIconFile</key>
			<string></string>
			<key>CFBundleTypeName</key>
			<string>DocumentType</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>????</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>NSDocumentClass</key>
			<string>$(PRODUCT_MODULE_NAME).Document</string>
		</dict>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>md</string>
			</array>
			<key>CFBundleTypeIconFile</key>
			<string></string>
			<key>CFBundleTypeName</key>
			<string>DocumentType</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>????</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>NSDocumentClass</key>
			<string>$(PRODUCT_MODULE_NAME).Document</string>
		</dict>
	</array>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIconFile</key>
	<string>MDEtcher.icns</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>\(buildNumber.trimmingCharacters(in: .whitespacesAndNewlines))</string>
	<key>LSMinimumSystemVersion</key>
	<string>$(MACOSX_DEPLOYMENT_TARGET)</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2020 psksvp (psksvp@gmail.com). All rights reserved.</string>
	<key>NSMainStoryboardFile</key>
	<string>Main</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSSupportsAutomaticTermination</key>
	<true/>
	<key>NSSupportsSuddenTermination</key>
	<true/>
</dict>
</plist>
"""
print("Building build number -> \(buildNumber)")
try? plist.write(toFile: "./MDEtcher/Info.plist", atomically: true, encoding: .utf8)