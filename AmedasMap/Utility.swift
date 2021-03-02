//
//  Utility.swift
//  AmedasMap
//
//  Created by tasshy on 2021/02/28.
//

import Foundation

public func LOG(_ body: String, filename: String = #file, functionName: String = #function, line: Int = #line) {
    #if DEBUG
        var file = filename.components(separatedBy: "/").last ?? filename
        file = file.replacingOccurrences(of: ".swift", with: "", options: [], range: nil)
        
        //print("\(DebugLog._currentDateString()) [\(file).\(functionName):\(line)] \(body)")    // print functionName
        NSLog("[%@:%d] %@", file, line, body)
    #endif
}

let TimeZoneJST = TimeZone(identifier: "JST")
