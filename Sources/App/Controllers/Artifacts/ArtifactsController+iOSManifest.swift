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
                                        <string>%@IPA_URL%@</string>
                                </dict>
                        </array>
                        <key>metadata</key>
                        <dict>
                                <key>bundle-identifier</key>
                                <string>%@BUNDLE_ID%@</string>
                                <key>bundle-version</key>
                                <string>%@BUNDLE_VERSION%@</string>
                                <key>kind</key>
                                <string>software</string>
                                <key>title</key>
                                <string>%@APP_NAME%@</string>
                        </dict>
                </dict>
        </array>
</dict>
</plist>
"""
extension ArtifactsController {
    class func generateiOsManifest(absoluteIpaUrl:String,bundleIdentifier:String,bundleVersion:String,ApplicationName:String) -> String {
        
        //DO NOT USE String(format: ....) it's does not work on Linux
         let manifestTemplateFilled = manifestTemplate.replacingOccurrences(of: "%@IPA_URL%@", with: absoluteIpaUrl)
            .replacingOccurrences(of: "%@BUNDLE_ID%@", with: bundleIdentifier)
            .replacingOccurrences(of: "%@BUNDLE_VERSION%@", with: bundleVersion)
            .replacingOccurrences(of: "%@APP_NAME%@", with: ApplicationName)
        
        return manifestTemplateFilled
    }
}
