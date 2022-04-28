//
//  Tools.swift
//  App
//
//  Created by Rémi Groult on 26/02/2019.
//

import Foundation
//import CryptoKit

func random(_ n: Int) -> String
{
    let a = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    //let allowedCharacters = "!\"#'$%&()*+-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_$"
    
    var s = ""
    let randomData:[UInt8] = Array.random(count: n)
        //OSRandom().generateData(count: n)
    
    for byte in randomData {
        let r = Int(byte%UInt8(a.count))
         s += String(a[a.index(a.startIndex, offsetBy: r)])
    }
    
    return s
}
