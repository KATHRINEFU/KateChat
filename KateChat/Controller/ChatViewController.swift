//
//  ChatViewController.swift
//  KateChat
//
//  Created by KateFu on 2/10/23.
//

import UIKit
import MessageKit

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
    
    private var messages = [Message]()
    
    private let selfSender = Sender(senderId: "1", displayName: "Kim Kardashian", photoURL: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("How are you?")))
        messages.append(Message(sender: selfSender, messageId: "2", sentDate: Date(), kind: .text("How are you? It's a lovely day")))
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("How are you? It's a lovely day, I miss you")))
        
        view.backgroundColor = .purple
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}


