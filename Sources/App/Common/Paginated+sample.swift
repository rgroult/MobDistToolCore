//
//  Paginated+sample.swift
//  App
//
//  Created by Remi Groult on 20/10/2019.
//

import Pagination

extension Paginated {
    static func sample(obj:M)-> Paginated {
        return Paginated(page: PageInfo(position: Position(current: 0, max: 0), data: PageData(per: 20, total: 1)), data: [obj])
    }
}
