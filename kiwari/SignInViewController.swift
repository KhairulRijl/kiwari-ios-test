//
//  SignInViewController.swift
//  kiwari
//
//  Created by Khairul Rijal on 26/02/20.
//  Copyright © 2020 Khairul Rijal. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let _ = Auth.auth().currentUser {
            let userViewController = UserTableViewController()
            let navController = UINavigationController(rootViewController: userViewController)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true, completion: nil)
        }
    }

    @IBAction func loginTap(_ sender: Any) {
        signIn()
    }
    
    func signIn() {
        guard !emailField.text!.isEmpty && isValidEmail(email: emailField.text!) else {
            return showAlert(with: "Input Valid Email")
        }
        
        guard !passwordField.text!.isEmpty else {
            return showAlert(with: "Password is Required")
        }
        
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) { (result, error) in
            guard error == nil else {
                return self.showAlert(with: error!.localizedDescription)
            }
            
            DispatchQueue.main.async {
                let userViewController = UserTableViewController()
                let navController = UINavigationController(rootViewController: userViewController)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true, completion: nil)
            }
        }
    }
    
    func showAlert(with message: String) {
        let alertController = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func isValidEmail(email: String) -> Bool{
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
