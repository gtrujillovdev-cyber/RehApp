//
//  Item.swift
//  RehApp
//
//  Created by Gabriel Trujillo Vallejo on 26/2/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
