//
//  Logger.swift
//  Ayero
//
//  Created by Yahor Paulikau on 7/11/17.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import Foundation

class LogDateFormatter {

    var dateFormatter: DateFormatter
        
    init(_ format: String) {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = format 
    }

    func getDateFormat(_ d: Date) -> String {
        return dateFormatter.string(from: d)
    }
}
