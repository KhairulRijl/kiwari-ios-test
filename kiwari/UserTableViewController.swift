//
//  UserTableViewController.swift
//  kiwari
//
//  Created by Khairul Rijal on 27/02/20.
//  Copyright © 2020 Khairul Rijal. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class UserTableViewController: UITableViewController {
    
    private let db = Firestore.firestore()
    private var usersListener: ListenerRegistration?
    private var usersRefrence: CollectionReference {
      return db.collection("users")
    }
    
    var users = [User]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        
        db.settings = settings
        
        fetchUser()
        setupLeftButton()
        observeUsers()
    }
    
    deinit {
        usersListener?.remove()
    }
    
    func observeUsers() {
        usersListener = usersRefrence.addSnapshotListener({ (querySnapshot, error) in
            guard let snapshot = querySnapshot else {
                return
            }
            
            snapshot.documentChanges.forEach { (documentChange) in
                switch documentChange.type {
                case .added:
                    DispatchQueue.main.async {
                        let user = User(document: documentChange.document)
                        if !(user.id == Auth.auth().currentUser!.uid) {
                           self.users.append(user)
                           self.tableView.insertRows(at: [IndexPath(row: (self.users.count - 1) , section: 0)], with: .automatic)
                        }
                        
                    }
                default:
                    break
                }
            }
        })
    }
    
    func fetchUser() {
        db.collection("users").document(Auth.auth().currentUser!.uid).getDocument { (documentSnapshot, error) in
            guard let snapshot = documentSnapshot else {
                return
            }
            
            DispatchQueue.main.async {
                self.setupTitleView(user: User(document: snapshot))
            }
        }
    }
    
    func setupLeftButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "LOGOUT", style: .plain, target: self, action: #selector(handleLogout))
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
            dismiss(animated: true, completion: nil)
        } catch let logoutError {
            print(logoutError)
        }
    }
    
    func setupTitleView(user: User) {
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = users[indexPath.row].name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = self.users[indexPath.row]
        let chatViewController = ChatViewController(user: user)
        self.navigationController?.pushViewController(chatViewController, animated: true)
    }

}
