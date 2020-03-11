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
                                <dict>
                                    <key>kind</key>
                                    <string>display-image</string>
                                    <key>needs-shine</key>
                                    <true/>
                                    <key>url</key>
                                    <string>%@ICON_URL%@</string>
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
    class func generateiOsManifest(absoluteIpaUrl:String,bundleIdentifier:String,bundleVersion:String,ApplicationName:String, ApplicationIconUrl:String) -> String {
        
        //DO NOT USE String(format: ....) it's does not work on Linux
         let manifestTemplateFilled = manifestTemplate.replacingOccurrences(of: "%@IPA_URL%@", with: absoluteIpaUrl)
            .replacingOccurrences(of: "%@BUNDLE_ID%@", with: bundleIdentifier)
            .replacingOccurrences(of: "%@BUNDLE_VERSION%@", with: bundleVersion)
            .replacingOccurrences(of: "%@APP_NAME%@", with: ApplicationName)
            .replacingOccurrences(of: "%@ICON_URL%@", with: ApplicationIconUrl)
        
        return manifestTemplateFilled
    }
}

let defaultDownloadIcon = "data:image/png;base64,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"
