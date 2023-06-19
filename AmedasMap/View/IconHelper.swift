//
//  IconHelper.swift
//  AmedasMap
//
//  Created by tasshy on 2023/06/19.
//

import UIKit

enum IconHelper {
    static let defaultSize = CGSize(width: 15, height: 15)
    
    static func drawCircle(color: UIColor,
                           borderColor: UIColor = .white,
                           size: CGSize = defaultSize) -> UIImage? {
        //LOG(#function + ", color:\(color)")
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        let rect = CGRect(origin: .zero, size: size)
        let radius = min(size.width, size.height) / 2 - 3

        // 色を指定
        context.setFillColor(color.cgColor)
        context.setStrokeColor(borderColor.cgColor)

        // 円を描画
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        path.stroke()
        path.fill()

        // 画像を出力
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    // 矢羽を表示に設定
    static func drawArrow(direction: Int,
                          color: UIColor,
                          borderColor: UIColor = .white,
                          size: CGSize = defaultSize) -> UIImage? {
        if direction == 0 {
            return drawCircle(color: color, borderColor: borderColor, size: size)
        }
        guard direction > 0, direction <= 16 else { return nil }
        
        //LOG(#function + ", direction:\(direction), color:\(color)")
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        let rect = CGRect(origin: .zero, size: size)

        // 色を指定
        context.setFillColor(color.cgColor)
        context.setStrokeColor(borderColor.cgColor)
        
        // 矢羽を描画
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -1.0))
        path.addLine(to: CGPoint(x: 5.0, y: -5.0))
        path.addLine(to: CGPoint(x: 0, y: 7.0))
        path.addLine(to: CGPoint(x: -5.0, y: -5.0))
        path.close()
        
        // 方角にあわせて回転
        let rotation: CGFloat = 2 * .pi * CGFloat(direction) / 16
        path.apply(CGAffineTransform(rotationAngle: rotation))
        path.apply(CGAffineTransform(translationX: rect.midX, y: rect.midY))
        
        path.stroke()
        path.fill()

        // 画像を出力
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
