//
//  ArtifactsController+iOSManifest.swift
//  App
//
//  Created by Remi Groult on 18/06/2019.
//

import Foundation

let manifestTemplate = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>items</key>
        <array>
                <dict>
                        <key>assets</key>
                        <array>
                                <dict>
                                        <key>kind</key>
                                        <string>software-package</string>
                                        <key>url</key>
                                        <string>%@</string>
                                </dict>
                        </array>
                        <key>metadata</key>
                        <dict>
                                <key>bundle-identifier</key>
                                <string>%@</string>
                                <key>bundle-version</key>
                                <string>%@</string>
                                <key>kind</key>
                                <string>software</string>
                                <key>title</key>
                                <string>%@</string>
                        </dict>
                </dict>
        </array>
</dict>
</plist>
"""
extension ArtifactsController {
    class func generateiOsManifest(absoluteIpaUrl:String,bundleIdentifier:String,bundleVersion:String,ApplicationName:String) -> String {
        return NSString(format: manifestTemplate as NSString, absoluteIpaUrl,bundleIdentifier,bundleVersion,ApplicationName) as String
    }
}
