//
//  CreateShareKey.swift
//  ChatAppAES
//
//  Created by quynb on 13/05/2022.
//

import Foundation
import BigInt
import CryptoSwift
import FirebaseDatabase

var MAX_RANDOM_NUMBER = 2147483648
var MAX_PRIME_NUMBER = 2147483648


final class CreateShareKey {
    static var aes: AES? = nil
    static let shared = CreateShareKey()
    func initAES(sharedSecretKeyValue: String, key_path: String, ivString: String) -> AES{
        let cryptoDHKey = String(sharedSecretKeyValue)
        
        let password: [UInt8] = Array(cryptoDHKey.utf8)
        let salt: [UInt8] = Array("at140446".utf8)
        let key_aes = UserDefaults.standard.object(forKey: "key_aes_\(key_path)")
        if (key_aes == nil) {
            let key = try! PKCS5.PBKDF2(
                password: password,
                salt: salt,
                iterations: 4096,
                keyLength: 32, /* AES-256 */
                variant: .sha256
            ).calculate()
            UserDefaults.standard.set(key, forKey: "key_aes_\(key_path)")
            var iv: Array<UInt8> = []
            let dataIv = Data(base64Encoded: ivString, options: .ignoreUnknownCharacters)
            iv = [UInt8](dataIv! as Data)
            let aesElement = try! AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
            return aesElement
        } else {
            let key = key_aes as! Array<UInt8>
            var iv: Array<UInt8> = []
            let dataIv = Data(base64Encoded: ivString, options: .ignoreUnknownCharacters)
            iv = [UInt8](dataIv! as Data)
            let aesElement = try! AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
            return aesElement
        }
        //            if (UserDefaults.standard.value(forKey: "iv") != nil) {
        //                iv = UserDefaults.standard.value(forKey: "iv") as! Array<UInt8>
        //                aes = try! AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
        //            } else {
        //                let key_path = ConversationsViewController.key_infor_path
        
        //            }
    }
    
    func encrypt(mess: String, aes: AES) -> String {
        let inputData = Data(mess.utf8)
        let encryptBytes = try! aes.encrypt(inputData.bytes)
        return (encryptBytes.toBase64())
    }
    
    func decrypt(cipherText: String, aes: AES) -> String {
        let decrypted = try! aes.decrypt(Array(base64: cipherText))
        
        let result = String(data: Data(decrypted), encoding: .utf8) ?? ""
        return result
    }
    
    func GetIV() {
        
    }
    
    func createIV() -> String {
        let iv = AES.randomIV(AES.blockSize)
        return (iv.toBase64())
    }
    
    func CreateExchangeKey(receiverPublicKeyValue: String) -> Int {
        var g = CreateShareKey.shared.generatePrimeNumber()
        var m = CreateShareKey.shared.generatePrimeNumber()
        
        if (g > m) {
            let swap = g
            g = m
            m = swap
        }
        
        let senderSecretKeyValue = CreateShareKey.shared.generateRandomNumber() % MAX_RANDOM_NUMBER
        //        let senderPublicKeyValue = CreateShareKey.shared.powermod(g, power: senderSecretKeyValue, modulus: m)
        
        let sharedSecretKeyValue = CreateShareKey.shared.powermod(Int(receiverPublicKeyValue)!, power: senderSecretKeyValue, modulus: m)
        
        return sharedSecretKeyValue;
    }
    
    func powermod(_ base: Int, power: Int, modulus: Int) -> Int {
        var result: Int64 = 1
        var i = 31
        while i >= 0 {
            result = Int64(Int((result * result)) % modulus)
            if (power & (1 << i)) != 0 {
                result = Int64((Int(result) * base) % modulus)
            }
            i -= 1
        }
        return Int(result)
    }
    
    func generateRandomNumber() -> Int {
        var key: UInt32 = 0
        key = arc4random() % UInt32(MAX_RANDOM_NUMBER)
        return Int(key)
    }
    
    func numTrailingZeros(_ n: Int) -> Int {
        var tmp = n
        var result = 0
        for _ in 0..<32 {
            if (tmp & 1) == 0 {
                result += 1
                tmp = tmp >> 1
            } else {
                break
            }
        }
        return result
    }
    
    //  Converted to Swift 5.6 by Swiftify v5.6.21858 - https://swiftify.com/
    func millerRabinPass(_ a: Int, modulus n: Int) -> Bool {
        var d = n - 1
        let s = numTrailingZeros(d)
        
        d >>= s
        var aPow = powermod(a, power: d, modulus: n)
        if aPow == 1 {
            return true
        }
        for _ in 0..<(s - 1) {
            if aPow == n - 1 {
                return true
            }
            aPow = powermod(aPow, power: 2, modulus: n)
        }
        if aPow == n - 1 {
            return true
        }
        return false
    }
    
    func millerRabinPrimalityTest(_ n: Int, trials: Int) -> Bool {
        if n <= 1 {
            return false
        } else if n == 2 {
            return true
        } else if millerRabinPass(2, modulus: n) && (n <= 7 || millerRabinPass(7, modulus: n)) && (n <= 61 || millerRabinPass(61, modulus: n)) {
            return true
        } else {
            return false
        }
    }
    
    public func generatePrimeNumber() -> Int {
        
        var result = generateRandomNumber() % MAX_PRIME_NUMBER
        
        //ensure it is an odd number
        if (result & 1) == 0 {
            result += 1
        }
        
        // keep incrementally checking odd numbers until we find
        // an integer of high probablity of primality
        while true {
            if millerRabinPrimalityTest(result, trials: 5) == true {
                //printf("\n%d - PRIME", result);
                return result
            } else {
                //printf("\n%d - COMPOSITE", result);
                result += 2
            }
        }
    }
    
    private static func generateDHKey(base: String, power: String, modulus : String) -> BigInt{
        
        
        let g = BigInt(base)
        let privateKey = BigInt(power)
        let p = BigInt(modulus )
        
        // pow mod formula to get key
        let key = g!.power(privateKey!, modulus: p!)
        
        return key
        
        
    }
    
    private static func getDHPrivateRandomNumberKey() -> String {
        
        var privateDHKey = ""
        
        // generate random keys
        for _ in 1...30 {
            
            privateDHKey += String(Int(arc4random_uniform(UInt32(42949672)) + UInt32(10)))
            
        }
        
        return privateDHKey
    }
    
    static func generateDHExchangeKeys(generator: String, primeNumber : String) -> DHKey {
        
        let privateDHKey = getDHPrivateRandomNumberKey()
        let publicKey = String(generateDHKey(base: generator, power: privateDHKey, modulus: primeNumber))
        
        let dhKeys = DHKey(privateKey: privateDHKey, publicKey: publicKey)
        
        return dhKeys
    }
    
    static func generateDHCryptoKey(privateDHKey: String, serverPublicDHKey: String, primeNumber : String) -> String {
        
        let cryptoKey = String(generateDHKey(base: serverPublicDHKey, power: privateDHKey, modulus: primeNumber))
        return cryptoKey
    }
}

struct DHKey {
    
    var privateKey: String?
    var publicKey: String?
    
    init(privateKey: String, publicKey: String) {
        
        self.privateKey = privateKey
        self.publicKey = publicKey
        
    }
}
