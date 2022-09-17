//
//  Utility.swift
//  AmedasMap
//
//  Created by tasshy on 2021/02/28.
//

import Foundation
import UIKit

public func LOG(_ body: String, filename: String = #file, line: Int = #line) {
    #if DEBUG
        var file = filename.components(separatedBy: "/").last ?? filename
        file = file.replacingOccurrences(of: ".swift", with: "")
        NSLog("[%@:%d] %@", file, line, body)
    #endif
}

extension Locale {
    static let posix = Locale(identifier: "en_US_POSIX")
    static let ja_JP = Locale(identifier: "ja_JP")
}

extension TimeZone {
    static let jst = TimeZone(identifier: "JST")
}

typealias ColorString = String

extension UIColor {
    // UIColor(hex: 0xF0F0F0, alpha: 0.7)
    convenience init(hex: UInt64, alpha: CGFloat = 1.0) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // UIColor(hex: "#F0F0F0", alpha: 0.7)
    convenience init?(hex: ColorString, alpha: CGFloat = 1.0) {
        let hexStr = hex.replacingOccurrences(of: "#", with: "")  // "#" を取り除く
        var color: UInt64 = 0
        if Scanner(string: hexStr).scanHexInt64(&color) {
            self.init(hex: color, alpha: alpha)
        } else {
            // 文字列が parse できなかった場合
            return nil
        }
    }
}
