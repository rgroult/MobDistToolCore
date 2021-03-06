import App
import Foundation
import Vapor

var mdtApp:Application!
func closeApp(){
    try? mdtApp.runningServer?.close().wait()
       mdtApp.shutdownGracefully { error in
           guard let error = error else { return }
           print("Error on shutDown :\(error)")
       }
}

signal(SIGINT) { signal in
    print("SIGINT received")
   closeApp()
}

signal(SIGKILL) { signal in
    print("SIGKILL received")
    closeApp()
}

signal(SIGTERM) { signal in
    print("SIGTERM received")
    closeApp()
}

do {
    mdtApp = try app(.detect())
    try mdtApp.run()
}catch {
    print("Unexpected error :\(error)")
}

