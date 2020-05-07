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
    private func formatErrorMessage(_ failedError:Error?) -> String{
        if let error = failedError {
            return "Reason: \(error)"
        }
        return ""
    }
    private func formatMessage(isSucess:Bool,value:String,failedError:Error?) -> String{
        var message = isSucess ? "Success" : "Failed ‼️"
        message += " - \(value) "

        message += formatErrorMessage(failedError)

        return message
    }

    private func formatMessage(value:String,failedError:Error?) -> String{
        return formatMessage(isSucess: failedError == nil , value: value, failedError: failedError)
    }
    
    func description() -> String {
        switch self {

        case .Register(let email, let isSuccess, let failedError):
            return "Register " + formatMessage(isSucess: isSuccess, value: "User:\(email)", failedError: failedError)
        case .Activation(let email, let isSuccess, let failedError):
            return "Activation " + formatMessage(isSucess: isSuccess, value: "User:\(email)", failedError: failedError)
        case .Login(let email, let isSuccess, let failedError):
             return "Login " + formatMessage(isSucess: isSuccess, value: "User:\(email)", failedError: failedError)
        case .RefreshLogin(let email, let isSuccess, let failedError):
            return "RefreshLogin " + formatMessage(isSucess: isSuccess, value: "User:\(email)", failedError: failedError)
        case .UpdateUser(let email, let isSuccess, let failedError):
             return "UpdateUser " + formatMessage(isSucess: isSuccess, value: "User:\(email)", failedError: failedError)
        case .DeleteUser(let email, let isSuccess, let failedError):
            return "DeleteUser " + formatMessage(isSucess: isSuccess, value: "User:\(email)", failedError: failedError)
        case .ForgotPassword(let email):
            return "ForgotPassword - User:\(email)"
        case .CreateApp(let app, let user):
            return "CreateApp - User:\(user.email), name:\(app.name), platorm:\(app.platform), uuid:\(app.uuid)"
        case .DeleteApp(let app, let user):
            return "DeleteApp - User:\(user.email), name:\(app.name), platorm:\(app.platform), uuid:\(app.uuid)"
        case .UpdateApp(let app, let user):
            return "UpdateApp - User:\(user.email), name:\(app.name), platorm:\(app.platform), uuid:\(app.uuid)"
        case .MaxVersion(let app, let appUuid, let failedError):
            return "MaxVersion " + formatMessage(value: "ApplicationName:\(String(describing: app?.name)), platorm:\(String(describing: app?.platform)), uuid:\(app?.uuid ?? appUuid ?? "")",failedError: failedError)
        case .UploadArtifact(let artifact, let failedError):
            return "UploadArtifact " + formatMessage(value: "Artifact:\(artifact?.description() ?? "" )",failedError: failedError)
        case .DeleteArtifact(let artifact, let failedError):
            return "DeleteArtifact " + formatMessage(value: "Artifact:\(artifact?.description() ?? "" )",failedError: failedError)
        case .DownloadArtifact(let artifact, let user, let failedError):
            return "DeleteArtifact " + formatMessage(value: "User:\(user?.email ?? "noUser"), Artifact:\(artifact.description())",failedError: failedError)
        }
    }
}

protocol ActivityLogger {
    func track(event:ActivityEvent)
}
