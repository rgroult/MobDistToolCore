import Vapor
import Meow

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    let logger:Logger = app.logger// try app.make()
    let meow = app.meow
    //try app.make(EventLoopFuture<Meow.Context>.self)
    //    .whenSuccess{ context in
           // do {
    let config = try app.appConfiguration() 
    do {
        let adminUserCreated = try createSysAdminIfNeeded(into: meow, with: config).wait()
        if adminUserCreated {
            logger.info("Admin user(\(config.initialAdminEmail)) created !")
        }
    }catch {
        logger.error("Unable to create initial admin user: \(error)")
    }
    /*
                let adminUserCreation = createSysAdminIfNeeded(into: meow, with: config)
    
                adminUserCreation.whenSuccess { result in
                        if result {
                            logger.info("Admin user(\(config.initialAdminEmail)) created !")
                        }
                }
                
                adminUserCreation.whenFailure{error in
                        logger.error("Unable to create initial admin user: \(error)")
                }*/
            /*}catch {
                 logger.error("Unable to create initial admin user: \(error)")
            }*/
            //display statistics of server
            meow.collection(for: User.self).count(where:Document()).whenSuccess({ count in
                logger.info("Number Users:\(count)")
            })
            meow.collection(for: MDTApplication.self).count(where: Document()).whenSuccess({ count in
                logger.info("Number Applications:\(count)")
            })
            meow.collection(for: Artifact.self).count(where: Document()).whenSuccess({ count in
                logger.info("Number Artifacts:\(count)")
            })
      //  }
    
    
}
