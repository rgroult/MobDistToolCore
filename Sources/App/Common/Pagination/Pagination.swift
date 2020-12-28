//
//  Pagination.swift
//  Pagination
//
//  Created by Anthony Castelli on 4/5/18.
//
import Vapor
import MongoKitten

func findWithPagination<T:Codable>(stages:[Document], paginationInfo:PaginationInfo, into collection:MongoCollection) -> MappedCursor<AggregateBuilderPipeline, PaginationResult<T>>{
    /*
     db.getCollection("MDTArtifact").aggregate([
     { $match : { application : ObjectId("6100093b50f6ab225ed36d0c") } },
     { $match : { branch : { "$ne" : "@@@@LAST####"} } },
     { $match : { branch : { "$eq" : "master"} } },
      { "$facet": {
          "totalData": [
                         
                         { $group : {
                             _id : {"sortIdentifier" : "$sortIdentifier","branch" : "$branch" },
                             date : { $max : "$createdAt"},
                             version: { $first : "$version" },
                             artifacts : { $push: "$$ROOT" }
                         }},
                         { "$skip": 3 },
                         { "$limit": 2 }
           ],
         "totalCount": [
           { "$count": "count" }
         ]
       }}
       ])
    */
    //let findStage = stages + paginationInfo.additionalStages
    let countStage:Document = [ "$count": "count" ]
    let facetStage:Document = [ "$facet" : [
        "data" : paginationInfo.additionalStages ,
                                "totalObjects" : [ countStage ]
                            ]]
    
    var aggregateStages = [AggregateBuilderStage]()
    for document in stages {
        aggregateStages.append(.init(document:document))
    }
    aggregateStages.append(.init(document:facetStage))
    return collection.aggregate(aggregateStages).decode(PaginationResult<T>.self)
}

