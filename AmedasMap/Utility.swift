//
//  Utility.swift
//  AmedasMap
//
//  Created by tasshy on 2021/02/28.
//

import Foundation
import UIKit

public func LOG(_ body: String, filename: String = #file, functionName: String = #function, line: Int = #line) {
    #if DEBUG
        var file = filename.components(separatedBy: "/").last ?? filename
        file = file.replacingOccurrences(of: ".swift", with: "", options: [], range: nil)
        
        //print("\(DebugLog._currentDateString()) [\(file).\(functionName):\(line)] \(body)")    // print functionName
        NSLog("[%@:%d] %@", file, line, body)
    #endif
}

let TimeZoneJST = TimeZone(identifier: "JST")

extension UIColor {
    // UIColor(hex: 0xF0F0F0, alpha: 0.7)
    public convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension UIImage {
    class func circle(size: CGSize, color: UIColor, borderColor: UIColor? = nil, backgroundColor: UIColor = .clear) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        let radius = min(size.width, size.height) / 2 - 1

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()!
        
        // 背景を透明に
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
        
        // 指定された色で円を描画
        context.setFillColor(color.cgColor)
        if let borderColor = borderColor {
            context.setStrokeColor(borderColor.cgColor)
        }

        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        path.stroke()
        path.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
