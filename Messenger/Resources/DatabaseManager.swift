//
//  DatabaseManager.swift
//  Messenger
//
//  Created by User on 7/18/20.
//  Copyright © 2020 Syrym Zhursin. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    public func test() {
        
        database.child("foo").setValue(["something": true])
    }
    
}

// MARK: - Account Management
extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void))  {
        database.child(email).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser) {
           database.child(user.email).setValue([
               "first_name": user.firstName,
               "last_name": user.lastName
           ])
       }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let email: String
//  let profilePictureUrl: String
}

