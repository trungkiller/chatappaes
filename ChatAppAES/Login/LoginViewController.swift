//
//  LoginViewController.swift
//  Side Menu
//
//  Created by Nguyễn Trung on 22/01/2021.
//  Copyright © 2021 Kyle Lee. All rights reserved.
//

import UIKit
import Firebase
import DTTextField
import NVActivityIndicatorView
import CryptoSwift

class LoginViewController: UIViewController {
    @IBOutlet weak var userName: DTTextField!
    @IBOutlet weak var passWord: DTTextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var singIn: UIButton!
    let loadingView = LoadingViewController()
    var loading: NVActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userName.text = "trung1@gmail.com"
        self.passWord.text = "trung98"
        logInButton.layer.cornerRadius = 20
        self.bottomTextField()
        let underline : [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue]
        let titleButton = NSMutableAttributedString(string: "Đăng ký",
                                                    attributes: underline)
        singIn.setAttributedTitle(titleButton, for: .normal)
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.title = "Đăng nhập"
        
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func bottomTextField() {
        userName.placeholderColor = .lightGray
        userName.floatPlaceholderColor = .darkGray
        userName.floatPlaceholderFont = UIFont(name: "Chalkboard SE", size: 11.0)!
        userName.dtLayer.backgroundColor = .none
        userName.borderColor = .darkGray
        userName.dtborderStyle = .bottom
        
        passWord.floatPlaceholderColor = .darkGray
        passWord.floatPlaceholderFont = UIFont(name: "Chalkboard SE", size: 11.0)!
        passWord.dtLayer.backgroundColor = .none
        passWord.dtborderStyle = .bottom
        passWord.borderColor = .darkGray
        passWord.placeholderColor = .lightGray
    }
    
    func createLoading() {
        loading = NVActivityIndicatorView.init(frame: CGRect(x: 10, y: 5, width: 45, height: 45), type: .ballSpinFadeLoader, color: .blue, padding: 0)
        loading.color = .darkGray
        loading.startAnimating()
        let alert = UIAlertController(title: nil, message: "Đang xử lý...", preferredStyle: .alert)
        alert.view.addSubview(loading)
        present(alert, animated: true, completion: nil)
    }
    @IBAction func logInClick(_ sender: Any) {
        createLoading()
        let email = self.userName.text!
        let pass = self.passWord.text!
        var messageNotify: String = ""
        Auth.auth().signIn(withEmail: email, password: pass) { (authResult, error) in
            if let error = error as NSError? {
                self.dismiss(animated: false, completion: nil)
                switch AuthErrorCode(rawValue: error.code) {
                case .operationNotAllowed: messageNotify = "Đăng nhập thất bại"; break
                case .userDisabled: messageNotify = "Tài khoản đã bị khoá"; break
                case .wrongPassword: messageNotify = "Mật khẩu không chính xác"; break
                case .invalidEmail: messageNotify = "Email không hợp lệ"; break
                default:
                    print("Error: \(error.localizedDescription)")
                    messageNotify = "Tài khoản không tồn tại";
                }
                let alert = UIAlertController(title: "Thông báo", message: messageNotify, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                print("User signs in successfully")
                let safeEmail = DatabaseManager.shared.safeEmail(Email: email)
                DatabaseManager.shared.getDataFor(path: safeEmail, completion: { resultt in
                    switch resultt {
                    case .success(let data):
                        guard let userDataa = data as? [String: Any],
                                let name = userDataa["name"] as? String else {
                                    return
                                }
                        UserDefaults.standard.set("\(name)", forKey: "name")
                        print("Login with name: \(name)")
                    case .failure(let error):
                        print("\(error)")
                    }
                })
                UserDefaults.standard.setValue(email, forKey: "Email")
                let loginState: Bool = true
                UserDefaults.standard.setValue(loginState, forKey: "logInState")
                DispatchQueue.main.async {
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
            self.dismiss(animated: false, completion: nil)
        }
    }
    @IBAction func signIn(_ sender: Any) {
        let signInView = CreateUserViewController.init()
        self.navigationController?.pushViewController(signInView, animated: true)
    }
}

extension String {

//    func aesEncrypt(key: String) throws -> String {
//
//        var result = ""
//
//        do {
//
//            let key: [UInt8] = Array(key.utf8) as [UInt8]
//            let aes = try! AES(key: key, blockMode: ECB(), padding: .pkcs5) // AES128 .ECB pkcs7
//            let encrypted = try aes.encrypt(Array(self.utf8))
//
//            result = encrypted.toBase64()
//
//            print("AES Encryption Result: \(result)")
//
//        } catch {
//
//            print("Error: \(error)")
//        }
//
//        return result
//    }
//
//    func aesDecrypt(key: String) throws -> String {
//
//        var result = ""
//
//        do {
//
//            let encrypted = self
//            let key: [UInt8] = Array(key.utf8) as [UInt8]
//            let aes = try! AES(key: key, blockMode: ECB(), padding: .pkcs5) // AES128 .ECB pkcs7
//            let decrypted = try aes.decrypt(Array(base64: encrypted))
//
//            result = String(data: Data(decrypted), encoding: .utf8) ?? ""
//
//            print("AES Decryption Result: \(result)")
//
//        } catch {
//
//            print("Error: \(error)")
//        }
//
//        return result
//    }
}
