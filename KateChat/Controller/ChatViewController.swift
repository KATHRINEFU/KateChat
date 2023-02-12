//
//  ChatViewController.swift
//  KateChat
//
//  Created by KateFu on 2/10/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import RealmSwift

struct Message: MessageType{
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
    
}

struct Sender: SenderType{
    var senderId: String
    
    var displayName: String
    
    var photoURL: String
}

class ChatViewController: MessagesViewController {
    
    public var isNewConversation = false
    public let otherUserEmail: String
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private var messages = [Message]()
    
    private var selfSender: Sender? = {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        
        return Sender(senderId: email, displayName: "Kim Kardashiam", photoURL: "")
    }()
    
    init(with email: String){
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("How are you?")))
//        messages.append(Message(sender: selfSender, messageId: "2", sentDate: Date(), kind: .text("How are you? It's a lovely day")))
//        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("How are you? It's a lovely day, I miss you")))
//
        view.backgroundColor = .purple
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageId = createMessageId() else{
            return
        }
        print("Sending: \(text)")
        //send message
        if isNewConversation{
            //create conversation in database
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message) { success in
                if success{
                    print("message sent")
                }else{
                    print("message failed to sent")
                }
            }
        }else{
            //append to existing conversation
        }
    }
    
    private func createMessageId()->String?{
        //date, otherUserEmail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") else{
            return nil
        }
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(currentUserEmail)_\(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("self sender is nil, email should be cached")
        return Sender(senderId: "12", displayName: "", photoURL: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}


