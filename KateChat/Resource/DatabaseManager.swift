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
    public func insertUser(with user: KateChatUser, completion: @escaping(Bool) -> (Void)){
        database.child(user.safeEmail).setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
        ]) { error, _ in
            guard error == nil else{
                print("failed to write into database")
                completion(false)
                return
            }
            completion(true)
        }
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
    var profilePictureFileName: String{
        return "\(safeEmail)_profile_picture.png"
    }
}
