//
//  DatabaseManager.swift
//  KateChat
//
//  Created by KateFu on 2/7/23.
//

import Foundation
import FirebaseDatabase
import SwiftUI
import RealmSwift

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
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool)->Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else{
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self]snapshot in
            guard var  userNode = snapshot.value as? [String: Any] else{
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch firstMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id":conversationId,
                "other_user_email":otherUserEmail,
                "name": name,
                "latest_message":[
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                ]
            ]
            
            let recipientNewConversationData: [String: Any] = [
                "id":conversationId,
                "other_user_email":safeEmail,
                "name": currentName,
                "latest_message":[
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                ]
            ]
            
            //update current recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self]snapshot in
                if var conversations = snapshot.value as? [[String: Any]]{
                    //append
                    conversations.append(recipientNewConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }else{
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            }
            
            //update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]]{
                // conversation array exists for the current user, append
                conversations.append(newConversationData)
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                }
            }else{
                // create conversation
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    private func finishCreatingConversation(name: String, conversationId:String, firstMessage: Message, completion: @escaping (Bool)->Void) {
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var messageContent = ""
        
        switch firstMessage.kind{
        case .text(let messageText):
            messageContent = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": messageContent,
            "date": dateString,
            "send_email": currentUserEmail,
            "is_read": false,
            "name": name,
        ]
        let value : [String: Any] = [
            "messages": [
                collectionMessage
            ]
            
        ]
        
        print("adding conversation: \(conversationId)")
        database.child("\(conversationId)").setValue(value, withCompletionBlock: {error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// fetch and return all conversation for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping(Result<[Conversation], Error>)->Void){
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else{
                    return nil
                }
                
                let latestMessageObj = LatestMessage(date: date, text: message, is_read: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObj)
            })
            completion(.success(conversations))
        }
    }
    
    /// get all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping(Result<[Message], Error>)->Void){
        
        database.child("\(id)/messages").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageId = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["send_email"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else{
                    
                    print("message fetching validation failed")
                    return nil
                    }
                print("message fetching validation completed")
                let sender = Sender(senderId: senderEmail, displayName: name, photoURL: "")
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: .text(content))
            })
            completion(.success(messages))
        })
        
    }
    
    /// send a message with target conversation and message
    public func sendMessage(to conversation: String,otherUserEmail: String, name: String, message: Message, completion: @escaping (Bool)->Void){
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(email: myEmail)
        
        //add new message to messages
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let strongSelf = self else{
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else{
                completion(false)
                return
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var messageContent = ""
            
            switch message.kind{
            case .text(let messageText):
                messageContent = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let newMessage: [String: Any] = [
                "id": message.messageId,
                "type": message.kind.messageKindString,
                "content": messageContent,
                "date": dateString,
                "send_email": currentUserEmail,
                "is_read": false,
                "name": name,
            ]
            
            currentMessages.append(newMessage)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error==nil else{
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else{
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String:Any] = [
                        "date": dateString,
                        "message": messageContent,
                        "is_read": false
                    ]
                    
                    var targetConversation: [String: Any]?
                    var position = 0
                    
                    for conversationDict in currentUserConversations{
                        if let currentId = conversationDict["id"] as? String, currentId == conversation{
                            targetConversation = conversationDict
                            break
                        }
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    guard let targetConversation = targetConversation else {
                        completion(false)
                        return
                    }

                    currentUserConversations[position] = targetConversation
                    strongSelf.database.child("\(currentEmail)/messages").setValue(currentUserConversations) { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        //update latest for recipient user
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else{
                                completion(false)
                                return
                            }
                            
                            let updatedValue: [String:Any] = [
                                "date": dateString,
                                "message": messageContent,
                                "is_read": false
                            ]
                            
                            var targetConversation: [String: Any]?
                            var position = 0
                            
                            for conversationDict in otherUserConversations{
                                if let currentId = conversationDict["id"] as? String, currentId == conversation{
                                    targetConversation = conversationDict
                                    break
                                }
                                position += 1
                            }
                            
                            targetConversation?["latest_message"] = updatedValue
                            guard let targetConversation = targetConversation else {
                                completion(false)
                                return
                            }

                            otherUserConversations[position] = targetConversation
                            strongSelf.database.child("\(otherUserEmail)/messages").setValue(otherUserConversations) { error, _ in
                                guard error == nil else{
                                    completion(false)
                                    return
                                }
                                
                                //update latest for recipient user
                                
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
        //update sender latest message
        //update recipient latest message
    }
}

extension DatabaseManager{
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>)->Void){
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else{
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
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
