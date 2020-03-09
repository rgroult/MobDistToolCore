//
//  ActivityLogger.swift
//  App
//
//  Created by Rémi Groult on 21/10/2019.
//

import Foundation

enum ActivityEvent {
    case Register(email:String,isSuccess:Bool, failedError:Error? = nil)
    case Activation(email:String,isSuccess:Bool, failedError:Error? = nil)
    case Login(email:String,isSuccess:Bool, failedError:Error? = nil)
    case RefreshLogin(email:String,isSuccess:Bool, failedError:Error? = nil)
    case UpdateUser(email:String,isSuccess:Bool, failedError:Error? = nil)
    case DeleteUser(email:String,isSuccess:Bool, failedError:Error? = nil)
    case ForgotPassword(email:String)
    
    case CreateApp(app:MDTApplication, user:User)
    case DeleteApp(app:MDTApplication, user:User)
    case UpdateApp(app:MDTApplication, user:User)
    case MaxVersion(app:MDTApplication?, appUuid:String?, failedError:Error? = nil)
    
    case UploadArtifact(artifact:Artifact? , failedError:Error? = nil)
    case DeleteArtifact(artifact:Artifact? , failedError:Error? = nil)
    case DownloadArtifact(artifact:Artifact,user:User?, failedError:Error? = nil)
    
    //case MaxVersion
    
    func description() -> String {
        return "\(self)"
    }
}

protocol ActivityLogger {
    func track(event:ActivityEvent)
}
