//
//  ChatViewController.swift
//  kiwari
//
//  Created by Khairul Rijal on 27/02/20.
//  Copyright © 2020 Khairul Rijal. All rights reserved.
//

import UIKit
import MessageKit
import Firebase
import FirebaseFirestore
import InputBarAccessoryView
import Kingfisher

class ChatViewController: MessagesViewController {
    
    var user: User
    var messages: [Message] = []
    
    private let db = Firestore.firestore()
    private var messagesReference: CollectionReference {
      return db.collection("messages")
    }
    private var messageListener: ListenerRegistration?
    var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/YYYY HH:mm:ss"
        return formatter
    }()
    
    deinit {
        messageListener?.remove()
    }
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        
        db.settings = settings
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChatCollection()
        setupInputBar()
        setupTitleView()
        observeMessages()
    }
    
    func setupChatCollection() {
        self.messagesCollectionView.messagesDataSource = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDisplayDelegate = self
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        }
    }
    
    func setupInputBar() {
        self.messageInputBar.delegate = self
        self.messageInputBar.inputTextView.placeholder = "Message.."
        self.messageInputBar.sendButton.setTitleColor(.red, for: .normal)
    }
    
    func setupTitleView() {
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.kf.setImage(with: URL(string: user.avatar)!)
        
        containerView.addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        
        containerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
    }
    
    func observeMessages() {
        self.messageListener = messagesReference.addSnapshotListener({ (querySnapshot, error) in
            guard let snapshot = querySnapshot else {
                return
            }
            
            snapshot.documentChanges.forEach { (documentChange) in
                switch documentChange.type {
                case .added:
                    self.messages.append(Message(document: documentChange.document))
                default:
                    break
                }
            }
            
            DispatchQueue.main.async {
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
    }
    
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return Sender(senderId: Auth.auth().currentUser?.uid ?? "", displayName: "Test", avatar: "Wow")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let date = formatter.string(from: messages[indexPath.section].sentDate)
        return NSAttributedString(string: date, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 13
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
    
}

extension ChatViewController: MessagesLayoutDelegate {
}

extension ChatViewController: MessagesDisplayDelegate {
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        self.addMessage(message: messageInputBar.inputTextView.text!)
    }
    
    func addMessage(message: String) {
        messagesReference.addDocument(data: [
            "message" : message,
            "senderId": Auth.auth().currentUser?.uid ?? "",
            "date": Int(Date().timeIntervalSince1970)]) { (error) in
            
            self.messageInputBar.sendButton.stopAnimating()
            
            if let _error = error {
                print(_error)
            }
                
            self.messageInputBar.inputTextView.text = ""
        }
    }
    
}
 
struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        print(data)
        sender = Sender(senderId: data["senderId"] as! String)
        messageId = document.documentID
        kind = .text(data["message"] as! String)
        sentDate = Date(timeIntervalSince1970: (data["date"] as! Double))
    }
}

struct Sender: SenderType {
    var senderId: String
    var displayName: String = ""
    var avatar: String?
    
    init(senderId: String) {
        self.senderId = senderId
    }
    
    init(senderId: String, displayName: String, avatar: String) {
        self.senderId = senderId
        self.displayName = displayName
        self.avatar = avatar
    }
}
