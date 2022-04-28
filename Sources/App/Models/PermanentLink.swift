//
//  PermanentLink.swift
//  
//
//  Created by Remi Groult on 19/10/2021.
//

import Foundation
import MongoKitten
import Meow

final class PermanentLink: Model {
    init(application: Reference<MDTApplication>, tokenInfo: Reference<TokenInfo>, branch: String, artifactName: String, validity: Int) {
        self.application = application
        self.tokenInfo = tokenInfo
        self.branch = branch
        self.artifactName = artifactName
        self.validity = validity
    }
    
    var _id = ObjectId()
    var application:  Reference<MDTApplication>
    var tokenInfo:  Reference<TokenInfo>
    let branch:String
    let artifactName:String
    let validity:Int
}

