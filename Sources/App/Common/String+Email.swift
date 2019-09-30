//
//  String+Email.swift
//  App
//
//  Created by Remi Groult on 04/03/2019.
//

import Foundation

extension String {
    // validate an email for the right format
  /*  func isValidEmail() -> Bool {
        
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let pred = NSPredicate(format:"SELF MATCHES %@", argumentArray:[regEx])
        return pred.evaluate(with: self)
    }*/
    
    func isValidEmail() -> Bool {
        let patternNormal = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        
        #if os(Linux)
        let regex = try? RegularExpression(pattern: patternNormal, options: .caseInsensitive)
        #else
        let regex = try? NSRegularExpression(pattern: patternNormal, options: .caseInsensitive)
        #endif
        
        return regex?.firstMatch(in: self, options: [], range: NSMakeRange(0, self.count)) != nil
    }
}

