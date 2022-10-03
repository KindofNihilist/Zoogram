//
//  FirebaseExtensions.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 30.09.2022.
//

import Foundation
import FirebaseDatabase

extension DataSnapshot {
    
    func decoded() throws -> ZoogramUser {
        let value = value
        let jsonData = try JSONSerialization.data(withJSONObject: value)
//        print("JSON DATA: \(jsonData)")
        let object = try JSONDecoder().decode(ZoogramUser.self, from: jsonData)
        print("OBJECT: \(object)")
        return object
    }
}
