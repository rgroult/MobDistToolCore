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
    case UpdateUser(email:String,isSuccess:Bool, failedError:Error? = nil)
    case ForgotPassword(email:String)
    
    case CreateApp(app:MDTApplication, user:User)
    case DeleteApp(app:MDTApplication, user:User)
    case UpdateApp(app:MDTApplication, user:User)
    
    case UploadArtifact(artifact:Artifact,user:User?)
    case DownloadArtifact(artifact:Artifact,user:User?)
    
    //case MaxVersion
}

protocol ActivityLogger {
    func track(event:ActivityEvent)
}
