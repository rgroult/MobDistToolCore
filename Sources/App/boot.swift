import Vapor
//import Meow

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    // Your code here
   // let context:Meow.Context = try app.make()
    let config = try app.make(MdtConfiguration.self)
    let logger:Logger = try app.make()
    try app.make(Future<Meow.Context>.self)
        .whenSuccess{ context in
            do {
                let adminUserCreation = try createSysAdminIfNeeded(into: context, with: config)
    
                adminUserCreation.whenSuccess { result in
                        if result {
                            logger.info("Admin user(\(config.initialAdminEmail)) created !")
                        }
                }
                
                adminUserCreation.whenFailure{error in
                        logger.error("Unable to create initial admin user: \(error)")
                }
            }catch {
                 logger.error("Unable to create initial admin user: \(error)")
            }
            //display statistics of server
            context.count(User.self).whenSuccess({ count in
                logger.info("Number Users:\(count)")
            })
            context.count(MDTApplication.self).whenSuccess({ count in
                logger.info("Number Applications:\(count)")
            })
            context.count(Artifact.self).whenSuccess({ count in
                logger.info("Number Artifacts:\(count)")
            })
        }
    
    
}
