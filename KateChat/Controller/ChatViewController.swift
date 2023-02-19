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
import SDWebImage

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

struct Media: MediaItem{
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
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
        messagesCollectionView.messageCellDelegate = self
        
        messageInputBar.delegate = self
        
        setupInputBtn()
    }
    
    private func setupInputBtn(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.onTouchUpInside { [weak self]_ in
            self?.presentPhotoInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photos", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
        let imageData = image.pngData(),
        let messageId = self.createMessageId(),
        let conversationId = conversationId,
        let name = self.title,
        let selfSender = selfSender else{
            return
        }
        
        let fileName = "photo_message_"+messageId.replacingOccurrences(of: " ", with: "-")+".png"
        
        //upload image
        StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
            guard let strongSelf = self else{
                return
            }
            switch result {
            case .success(let urlString):
                //ready to send message
                print("uploading message photo: \(urlString)")
                
                guard let url = URL(string: urlString),
                      let placeholder = UIImage(systemName: "plus") else{
                    return
                }
                
                let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .photo(media))
                
                DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, message: message) { success in
                    if success{
                        print("sent photo message succeed")
                    }else{
                        print("sent photo message failed")
                    }
                }
            case .failure(let error):
                print("message photo upload error: \(error)")
             
            }
        //send message
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
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        if isNewConversation{
            //create conversation in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self]success in
                if success{
                    print("message sent")
                    self?.isNewConversation = false
                }else{
                    print("message failed to sent")
                }
            }
        }else{
            //append to existing conversation
            guard let conversationId = conversationId, let name = self.title else{
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail,name: name, message: message) { success in
                if success {
                    print("message sent")
                }else{
                    print("message failed to send")
                }
            }
        }
    }
    
    public func createMessageId()->String?{
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else{
            return
        }
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
}

extension ChatViewController:MessageCellDelegate{
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        let message = messages[indexPath.section]
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}


