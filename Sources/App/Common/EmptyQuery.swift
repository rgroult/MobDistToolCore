//
//  EmptyQuery.swift
//  
//
//  Created by Rémi Groult on 17/01/2021.
//

import Foundation
import MongoKitten

public class EmptyQuery:MongoKittenQuery {
    public func makeDocument() -> Document {
        return Document()
    }
}

public func && (lhs: EmptyQuery, rhs: AndQuery) -> AndQuery {
    return rhs
}

public func && (lhs: AndQuery, rhs: EmptyQuery) -> AndQuery {
    return lhs
}
