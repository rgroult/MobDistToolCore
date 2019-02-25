import Vapor
import Meow

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    // Your code here
   // let context:Meow.Context = try app.make()
    try app.make(Future<Meow.Context>.self)
        .whenSuccess({ context in
            print("Context \(context)")
            do {
                print("Nbre of uers \(try context.count(User.self).wait())")
                //executeAndComplete(try context.count(User.self))
            }catch{
                
            }
            
            context.find(User.self).getAllResults()
                .whenSuccess { users in
                    print("User \(users.count)")
            }
        })
}
