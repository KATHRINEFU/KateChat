//
//  DatabaseManager.swift
//  KateChat
//
//  Created by KateFu on 2/7/23.
//

import Foundation
import FirebaseDatabase
import SwiftUI

//singleton
final class DatabaseManager{
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    static func safeEmail(email: String) ->String{
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
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
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String : String]]{
                    //apend to user dict
                    let newElement = [
                        ["name": user.firstName+" "+user.lastName,
                         "email": user.safeEmail]
                    ]
                    usersCollection.append(contentsOf: newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: {error, _ in
                        guard error==nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                
                }else{
                    //create user dict
                    let newCollection: [[String: String]] = [
                        ["name": user.firstName+" "+user.lastName,
                         "email": user.safeEmail]
                    ]
                    
                    self.database.child("users").setValue(newCollection,withCompletionBlock: {error, _ in
                        guard error==nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            }
            completion(true)
        }
    }
    
    public func getAllUsers(completion: @escaping(Result<[[String: String]], Error>)->Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String:String]] else{
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseErrors: Error{
        case failedToFetch
    }
}

//MARK: - Sending massages / conversations
extension DatabaseManager{
    /// create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool)->Void){
        
    }
    
    /// fetch and return all conversation for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping(Result<String, Error>)->Void){
        
    }
    
    /// get all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, compleiton: @escaping(Result<String, Error>)->Void){
        
    }
    
    /// send a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool)->Void){
        
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
