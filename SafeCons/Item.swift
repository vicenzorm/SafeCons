//
//  Item.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 26/03/26.
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
