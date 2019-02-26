//
//  Tools.swift
//  App
//
//  Created by Rémi Groult on 26/02/2019.
//

import Foundation

func random(_ n: Int) -> String
{
    let a = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    
    var s = ""
    
    for _ in 0..<n
    {
        let r = Int(arc4random_uniform(UInt32(a.characters.count)))
        
        s += String(a[a.index(a.startIndex, offsetBy: r)])
    }
    
    return s
}
