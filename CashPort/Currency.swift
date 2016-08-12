//
//  Currency.swift
//  CashPort
//
//  Created by Gabriel Nadel on 8/9/16.
//  Copyright © 2016 Treehouse. All rights reserved.
//

import Foundation
import CoreData
import Freddy

class Currency: NSManagedObject {
    
static let identifier = "Currency"
    
    @NSManaged var code: String?
    @NSManaged var usdRate: NSNumber?
    @NSManaged var fullName: String?
   
    var pickerName : String {
    get{
       return "\(fullName!) (\(code!))"
    }
        }
}