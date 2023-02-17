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
    public var sender: SenderType
    
    public var messageId: String
    
    public var sentDate: Date
    
    public var kind: MessageKind
    
}

extension MessageKind{
    var messageKindString: String{
        switch self{
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType{
    public var senderId: String
    
    public var displayName: String
    
    public var photoURL: String
}

class ChatViewController: MessagesViewController {
    
    public var isNewConversation = false
    public let otherUserEmail: String
    private let conversationId: String?
    
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
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        return Sender(senderId: safeEmail, displayName: "Me", photoURL: "")
    }()
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool){
        print("start fetching messages")
        DatabaseManager.shared.getAllMessagesForConversation(with: id) {[weak self] result in
            switch result{
            case .success(let messages):
                guard !messages.isEmpty else{
                    return
                }
                print("successfully fetching non empty messages")
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom{
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
                
            case .failure(let error):
                print("failed to get messages, \(error)")
            }
        }
    }
    
    init(with email: String, id: String?){
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .purple
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
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
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { success in
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
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
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
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}


