//
//  DatabaseManager.swift
//  KateChat
//
//  Created by KateFu on 2/7/23.
//

import Foundation
import FirebaseDatabase

//singleton
final class DatabaseManager{
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
}

// MARK: Account Management
extension DatabaseManager{
    public func userExists(with email: String, completion: @escaping ((Bool)-> Void)){
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            completion(true)
        }
    }
    /// insert  new user to database
    public func insertUser(with user: KateChatUser){
        database.child(user.safeEmail).setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
        ])
    }
}

struct KateChatUser{
    let firstName: String
    let lastName: String
    let email: String
    var safeEmail : String{
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
//    let profilePictureUrl: String
}
