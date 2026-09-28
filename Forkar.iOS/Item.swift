//
//  Item.swift
//  Forkar
//
//  Created by iJeriX OrtiX on 8/07/26.
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
