//
//  MappedCursor+Pagination.swift
//  App
//
//  Created by Rémi Groult on 15/10/2019.
//

import MongoKitten
import Vapor
import Meow
//import FluentKit
/*
let MappedCursorDefaultPageSize:UInt = 50

enum PaginationSort:String {
    case ascending
    case descending
    func convert(field:String) -> MongoKitten.Sort {
        switch self {
        case .ascending:
                return Sort([(field, SortOrder.ascending)])
        case .descending:
            return Sort([(field, SortOrder.descending)])
        }
    }
}*/
public typealias PaginationStageBlock = (_ totalCount:Int) -> (PageInfo,[AggregateBuilderStage])
extension Request {
    func extractPaginateInfoKO(sortFields:[String:String],defaultSort:String)-> PaginationStageBlock {
        
        let aggregateStages:PaginationStageBlock = {(totalCount:Int)  in
            var stages = [AggregateBuilderStage]()
            let req = self
            
            //page info
            var page = Int((try? req.query.get(UInt.self, at: "page")) ?? 0)
            page = max (0 , page)
            var perPage = Int((try? req.query.get(UInt.self, at: "per")) ?? MappedCursorDefaultPageSize)
            perPage = max (0 , perPage)
            let skipItems = page * perPage
            
            //sort info
            let sortOrder:PaginationSort
            if let sortOrderQuery = try? req.query.get(String.self, at: "orderby"), let sort = PaginationSort(rawValue: sortOrderQuery){
                sortOrder = sort
            }else {
                sortOrder = .descending
            }
            let sortValue = try? req.query.get(String.self, at: "sortby")
            let sortBy:String
            if let field = sortFields[sortValue ?? ""] {
                sortBy = field
            }else {
                sortBy = sortFields[defaultSort]!
            }
            
            let pageData = PageData(per: perPage, total: totalCount)
            let maxPosition = max(0, Int(ceil(-1.0 + Double(totalCount) / Double(perPage))))
            let position = Position(current: page, max: maxPosition)
           // return self.sort(sortOrder.convert(field: sortBy)).skip(skipItems).limit(perPage)
             //   .getPageResult(position,pageData)
            let paginatedInfo = PageInfo(position: position, data: pageData)
            stages.append(.sort(sortOrder.convert(field: sortBy)))
            stages.append(.skip(skipItems))
            stages.append(.limit(perPage))
            
            return (paginatedInfo,stages)
        }
        
        return aggregateStages
    }
}
//let cursor:MappedCursor<MappedCursor<FindQueryBuilder, User>,UserDto>
//extension MappedCursor<FindQueryBuilder, Content> {// where Element:Content
//typealias MappedModelCursor<CursorElement:Model> = MappedCursor<FindQueryBuilder, CursorElement>

typealias PaginatedMappedCursor<CursorElement:Model,Element:Content> = MappedCursor<MappedCursor<AggregateBuilderPipeline, CursorElement>,Element>
/*
extension MappedCursor<MappedCursor<AggregateBuilderPipeline,ArtifactGrouped>,ArtifactDto> {
    
}*/

//typealias MappedModelCursor = MappedCursor<FindQueryBuilder, Element> where Element:Model
//typealias PaginateMappedCursor<O:Content> = MappedCursor<MappedModelCursor<C:Model>,O>
//extension MappedCursor where Base == MappedModelCursor<CursorElement> , Element:Content, CursorElement:Model{
//extension MappedCursor where Base == MappedModelCursor<C>, Element:Content, C:Model{
//extension MappedCursor where MappedCursor<FindQueryBuilder, Element>
extension PaginatedMappedCursor {
    
    func paginateKO<M: ReadableModel>(for req:Request, model:M.Type, sortFields:[String:String],defaultSort:String,countQuery:EventLoopFuture<Int>) -> EventLoopFuture<Paginated<Element>>{
        return countQuery.flatMap{ count in
            self.paginate(for: req, model:model, sortFields: sortFields,defaultSort:defaultSort, totalCount: count)
        }
    }
    /*
    func paginate<M: ReadableModel>(for req:Request, model:M.Type, sortFields:[String:String],defaultSort:String,findQuery:MongoKittenQuery? = nil) -> EventLoopFuture<Paginated<Element>>{
        //extract "page" and "per" parameters
        
        //page info
        var page = Int((try? req.query.get(UInt.self, at: "page")) ?? 0)
        page = max (0 , page)
        var perPage = Int((try? req.query.get(UInt.self, at: "per")) ?? MappedCursorDefaultPageSize)
        perPage = max (0 , perPage)
        let skipItems = page * perPage
        
        //sort info
        let sortOrder:PaginationSort
        if let sortOrderQuery = try? req.query.get(String.self, at: "orderby"), let sort = PaginationSort(rawValue: sortOrderQuery){
            sortOrder = sort
        }else {
            sortOrder = .descending
        }
        let sortValue = try? req.query.get(String.self, at: "sortby")
        let sortBy:String
        if let field = sortFields[sortValue ?? ""] {
            sortBy = field
        }else {
            sortBy = sortFields[defaultSort]!
        }
        
        let collection = req.meow.collection(for: model)
        let query = findQuery?.makeDocument() ?? []
        
        return collection.count(where: query).flatMap{ totalCount in
            let pageData = PageData(per: perPage, total: totalCount)
            let maxPosition = max(0, Int(ceil(-1.0 + Double(totalCount) / Double(perPage))))
            let position = Position(current: Int(page), max: maxPosition)
            return collection.raw.find(query).sort(sortOrder.convert(field: sortBy))
                .skip(skipItems).limit(perPage)
                .getPageResult(position,pageData)
            //return self.sort(sortOrder.convert(field: sortBy)).skip(skipItems).limit(perPage)
              //  .getPageResult(position,pageData)
            // return context.collection(for: Artifact.self).raw.find(query).sort(Sort([("sortIdentifier", SortOrder.descending)])).firstResult().decode(Artifact.self)
        }
    }*/
    
    private func paginate<M: ReadableModel>(for req:Request, model:M.Type, sortFields:[String:String],defaultSort:String,totalCount:Int) -> EventLoopFuture<Paginated<Element>>{
        //extract "page" and "per" parameters
        
        //page info
        var page = Int((try? req.query.get(UInt.self, at: "page")) ?? 0)
        page = max (0 , page)
        var perPage = Int((try? req.query.get(UInt.self, at: "per")) ?? MappedCursorDefaultPageSize)
        perPage = max (0 , perPage)
        let skipItems = page * perPage
        
        //sort info
        let sortOrder:PaginationSort
        if let sortOrderQuery = try? req.query.get(String.self, at: "orderby"), let sort = PaginationSort(rawValue: sortOrderQuery){
            sortOrder = sort
        }else {
            sortOrder = .descending
        }
        let sortValue = try? req.query.get(String.self, at: "sortby")
        let sortBy:String
        if let field = sortFields[sortValue ?? ""] {
            sortBy = field
        }else {
            sortBy = sortFields[defaultSort]!
        }
        
        let pageData = PageData(per: perPage, total: totalCount)
        let maxPosition = max(0, Int(ceil(-1.0 + Double(totalCount) / Double(perPage))))
        let position = Position(current: page, max: maxPosition /* Int(ceil(Double(count) / Double(perPage)) - 1) *//* start indice is 0 */)
        
       // return self.sort(sortOrder.convert(field: sortBy)).skip(skipItems).limit(perPage)
         //   .getPageResult(position,pageData)
       
        let collection = req.meow.collection(for: model)
        let query:Document = [:]
        return collection.raw.find(query).sort(sortOrder.convert(field: sortBy))
            .skip(skipItems).limit(perPage)
            .getPageResult(position,pageData)
    }
    /*
    func getPageResult(_ position:Position,_ pageData:PageData) -> EventLoopFuture<Paginated<Element>>{
        return allResults().map({ arrayOfResult in
            let pageInfo = PageInfo(position: position, data: pageData)
            return Paginated (page: pageInfo, data: arrayOfResult)
        })
    }*/
}
extension FindQueryBuilder {
    func getPageResult<Element:Content>(_ position:Position,_ pageData:PageData) -> EventLoopFuture<Paginated<Element>>{
        return allResults().flatMapThrowing({ arrayOfResult in
            let decoder = BSONDecoder()
            print("Decode as \(Element.self)")
            let elts = try arrayOfResult.map { document in
                return try decoder.decode(Element.self, from: document)
            }
                
            let pageInfo = PageInfo(position: position, data: pageData)
            return Paginated (page: pageInfo, data: elts)
        })
    }
}
