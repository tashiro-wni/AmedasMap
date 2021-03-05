//
//  AmedasAnnotationView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/05.
//

import MapKit

final class AmedasAnnotationView: MKAnnotationView {
    private let size = CGSize(width: 15, height: 15)
    private let borderColor = UIColor.white
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        guard let reuseIdentifier = reuseIdentifier else { return }
        let ary = reuseIdentifier.components(separatedBy: ",")
        if ary.count == 2, ary[0] == "circle", let color = UIColor(hex: ary[1]) {
            drawCircle(color: color)
        } else if ary.count == 3, ary[0] == "arrow",
                  let direction = Int(ary[1]), let color = UIColor(hex: ary[2]) {
            drawArrow(direction: direction, color: color)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var alignmentRectInsets: UIEdgeInsets { .zero }

    private func drawCircle(color: UIColor) {
        //image = UIImage.circle(size: CGSize(width: 15, height: 15), color: color, borderColor: .white)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let rect = CGRect(origin: .zero, size: size)
        let radius = min(size.width, size.height) / 2 - 3

        // 背景を透明に
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(rect)
        
        // 指定された色で円を描画
        context.setFillColor(color.cgColor)
        context.setStrokeColor(borderColor.cgColor)

        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        path.stroke()
        path.fill()

        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    private func drawArrow(direction: Int, color: UIColor) {
        if direction == 0 {
            drawCircle(color: color)
            return
        }
        guard direction >= 1, direction <= 16 else { return }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let rect = CGRect(origin: .zero, size: size)

        context.setFillColor(color.cgColor)
        context.setStrokeColor(borderColor.cgColor)
        
        let original = CGPoint(x: rect.midX, y: rect.midY - 1.0)
        let circleAngle: CGFloat = (360.0 / 16.0)
        let angleConvert = (circleAngle * CGFloat(direction - 1)) + circleAngle
        let rotation: CGFloat = (.pi / 180) * angleConvert
        
        let path = UIBezierPath()
        path.move(to: original)
        path.addLine(to: CGPoint(x: rect.midX + 5.0, y: rect.midY - 5.0))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY + 7.0))
        path.addLine(to: CGPoint(x: rect.midX - 5.0, y: rect.midY - 5.0))
        path.addLine(to: original)
        path.close()
        
        path.apply(CGAffineTransform(translationX: -rect.midX, y: -rect.midY))
        path.apply(CGAffineTransform(rotationAngle: rotation))
        path.apply(CGAffineTransform(translationX: rect.midX, y: rect.midY))
        
        path.stroke()
        path.fill()

        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}
