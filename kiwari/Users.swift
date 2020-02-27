//
//  Users.swift
//  kiwari
//
//  Created by Khairul Rijal on 27/02/20.
//  Copyright © 2020 Khairul Rijal. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct User {
    var id: String
    var name: String
    var avatar: String
    
    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        print(data)
        id = document.documentID
        name = data["name"] as! String
        avatar = data["avatar"] as! String
    }
    
    init(document: DocumentSnapshot) {
        let data = document.data()!
        print(data)
        id = document.documentID
        name = data["name"] as! String
        avatar = data["avatar"] as! String
    }
}
