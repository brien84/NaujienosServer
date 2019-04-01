import Vapor

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    
    let coordinator = try Coordinator(on: app)
    //coordinator.start()
  
}
