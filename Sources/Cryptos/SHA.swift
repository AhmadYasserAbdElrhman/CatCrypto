//
//  SHA.swift
//  CatCrypto
//
//  Created by Kcat on 2017/12/28.
//  Copyright © 2017年 imkcat. All rights reserved.
//
// https://github.com/ImKcat/CatCrypto
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//

import Foundation
import CommonCryptoFramework
import SHA3

///  `CatSHA1Crypto` is the crypto for
/// [SHA-1](https://csrc.nist.gov/csrc/media/publications/fips/180/4/final/documents/fips180-4-draft-aug2014.pdf) function.
public class CatSHA1Crypto: CatCCHashingCrypto {
    public override init() {
        super.init()
        algorithm = .sha1
    }
}

/// Desired bit-length of the hash function output.
public enum CatSHA2HashLength {

    /// 224 bits.
    case bit224

    /// 256 bits.
    case bit256

    /// 384 bits.
    case bit384

    /// 512 bits.
    case bit512
}

/// Context for SHA-2 crypto.
public struct CatSHA2Context {

    /// Desired bit-length of the hash function output.
    public var hashLength: CatSHA2HashLength = .bit512

    /// Initialize the context.
    public init() {}

}

///  `CatSHA2Crypto` is the crypto for
/// [SHA-2](https://csrc.nist.gov/csrc/media/publications/fips/180/4/final/documents/fips180-4-draft-aug2014.pdf) function.
public class CatSHA2Crypto: CatCCHashingCrypto, Contextual {

    public typealias Context = CatSHA2Context

    public var context: CatSHA2Context {
        didSet {
            switch context.hashLength {
            case .bit224: algorithm = .sha224
            case .bit256: algorithm = .sha256
            case .bit384: algorithm = .sha384
            case .bit512: algorithm = .sha512
            }
        }
    }

    public required init(context: Context = CatSHA2Context()) {
        self.context = context
        super.init()
        algorithm = .sha512
    }

}

/// Desired bit-length of the hash function output.
public enum CatSHA3HashLength: Int {

    /// 224 bits.
    case bit224 = 28

    /// 256 bits.
    case bit256 = 32

    /// 384 bits.
    case bit384 = 48

    /// 512 bits.
    case bit512 = 64
}

/// Context for SHA-3 crypto.
public struct CatSHA3Context {

    /// Desired bit-length of the hash function output.
    public var hashLength: CatSHA3HashLength = .bit512

    /// Initialize the context.
    public init() {}

}

///  `CatSHA2Crypto` is the crypto for
/// [SHA-3](http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf) function.
public class CatSHA3Crypto: Contextual, Hashing {

    // MARK: - Contextual
    public typealias Context = CatSHA3Context

    public var context: CatSHA3Context

    public required init(context: CatSHA3Context = CatSHA3Context()) {
        self.context = context
    }

    // MARK: - Core
    /// Hash with SHA-3 function.
    ///
    /// - Parameter password: Password string.
    /// - Returns: Result code of hashing function, 0 if successful, 1 otherwise.
    func sha3Hash(password: String) -> (errorCode: CInt, hash: String) {
        let passwordLength = password.lengthOfBytes(using: .utf8)
        let passwordCString = UnsafeMutablePointer<CChar>(mutating: password.cString(using: .utf8))?
            .withMemoryRebound(to: CUnsignedChar.self,
                               capacity: passwordLength, { point in
                                return point
            })
        var result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: context.hashLength.rawValue)
        defer {
            result.deallocate()
        }
        var errorCode: CInt
        switch context.hashLength {
        case .bit224: errorCode = SHA3_224(result, passwordCString, passwordLength)
        case .bit256: errorCode = SHA3_256(result, passwordCString, passwordLength)
        case .bit384: errorCode = SHA3_384(result, passwordCString, passwordLength)
        case .bit512: errorCode = SHA3_512(result, passwordCString, passwordLength)
        }
        let hash = String.hexString(source: result,
                                    length: context.hashLength.rawValue)
        return (errorCode, hash)
    }

    // MARK: - Hashing
    public func hash(password: String) -> CatCryptoHashResult {
        let result = sha3Hash(password: password)
        let hashResult = CatCryptoHashResult()
        if result.errorCode == 0 {
            hashResult.value = result.hash
        } else {
            let error = CatCryptoError()
            error.errorCode = Int(result.errorCode)
            error.errorDescription = "Fail"
            hashResult.error = error
        }
        return hashResult
    }

}
