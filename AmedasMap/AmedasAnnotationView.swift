//
//  AmedasAnnotationView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/05.
//

import MapKit

// MARK: - AmedasElement 地図上でのアイコンの形を定義
private extension AmedasElement {
    enum Shape: String {
        case circle, arrow
    }
    
    var iconShape: Shape {
        switch self {
        case .temperature, .precipitation, .sun, .humidity:
            return .circle
        case .wind:
            return .arrow
        }
    }
}

// MARK: - AmedasData 地図上での表示を定義
extension AmedasData {
    // アイコンの色
    private static let elementColors: [AmedasElement: [ColorString]] = [
        .temperature:   [ "#9522E6", "#B2B2B2", "#3377FF", "#3377FF", "#56C6FF",
                          "#67CC33", "#FFD500", "#FF8800", "#F254B0", "#E60000" ],
        .precipitation: [ "#999999", "#45A3E5", "#002CB2", "#FFBF00", "#D90000" ],
        .wind:          [ "#999999", "#002CB2", "#5FB235", "#FFBF00", "#FF7F00", "#D90000" ],
        .sun:           [ "#999999", "#FFFF00", "#FFA500" ],
        .humidity:      [ "#999999", "#45A3E5", "#002CB2" ] ]

    static var allIdentifiers: [String] {
        var list: [String] = []
        for element in AmedasElement.allCases {
            guard let colors = elementColors[element] else {
                fatalError("colors not defined for \(element)")
            }
            
            switch element.iconShape {
            case .circle:
                for color in colors {
                    list.append([ element.iconShape.rawValue, color ].joined(separator: ","))
                }
            case .arrow:
                for dir in 0...16 {
                    for color in colors {
                        list.append([ element.iconShape.rawValue, String(dir), color ].joined(separator: ","))
                    }
                }
            }
        }
        return list
    }
    
    func reuseIdentifier(for element: AmedasElement) -> String? {
        guard let colors = Self.elementColors[element] else {
            fatalError("colors not defined for \(element)")
        }

        let colorIndex: Int
        let ary: [String]
        
        switch element {
        case .temperature:
            guard let temperature = temperature else { return nil }
            switch temperature {
            case  35 ... 100:  colorIndex = 9
            case  30 ..<  35:  colorIndex = 8
            case  25 ..<  30:  colorIndex = 7
            case  20 ..<  25:  colorIndex = 6
            case  15 ..<  20:  colorIndex = 5
            case  10 ..<  15:  colorIndex = 4
            case   5 ..<  10:  colorIndex = 3
            case   0 ..<   5:  colorIndex = 2
            case -10 ..<   0:  colorIndex = 1
            case -99 ..< -10:  colorIndex = 0
            default:  return nil
            }
            ary = [ element.iconShape.rawValue, colors[colorIndex] ]

        case .precipitation:
            guard let precipitation1h = precipitation1h else { return nil }
            switch precipitation1h {
            case 32 ... 500:  colorIndex = 4
            case 16 ..<  32:  colorIndex = 3
            case  4 ..<  16:  colorIndex = 2
            case  1 ..<   4:  colorIndex = 1
            case  0 ..<   1:  colorIndex = 0
            default:  return nil
            }
            ary = [ element.iconShape.rawValue, colors[colorIndex] ]

        case .wind:
            guard let windDirection = windDirection, let windSpeed = windSpeed else { return nil }
            switch windSpeed {
            case 25 ... 99:  colorIndex = 5
            case 20 ..< 25:  colorIndex = 4
            case 15 ..< 20:  colorIndex = 3
            case 10 ..< 15:  colorIndex = 2
            case  5 ..< 10:  colorIndex = 1
            case  0 ..<  5:  colorIndex = 0
            default:  return nil
            }
            ary = [ element.iconShape.rawValue, String(windDirection), colors[colorIndex] ]
            
        case .sun:
            guard let sun1h = sun1h else { return nil }
            switch sun1h * 60 {
            case 40 ... 60:  colorIndex = 2
            case 20 ..< 40:  colorIndex = 1
            case  0 ..< 20:  colorIndex = 0
            default: return nil
            }
            ary = [ element.iconShape.rawValue, colors[colorIndex] ]
            
        case .humidity:
            guard let humidity = humidity else { return nil }
            switch humidity {
            case 75 ... 100: colorIndex = 2
            case 50 ..<  75: colorIndex = 1
            case  0 ..<  50: colorIndex = 0
            default:  return nil
            }
            ary = [ element.iconShape.rawValue, colors[colorIndex] ]
        }
        
        return ary.joined(separator: ",")
    }
}

// MARK: - AmedasAnnotation
final class AmedasAnnotation: MKPointAnnotation {
    let point: AmedasPoint
    let amedasData: AmedasData
    let element: AmedasElement
    
    init(point: AmedasPoint, data: AmedasData, element: AmedasElement) {
        self.point = point
        amedasData = data
        self.element = element
        super.init()
        coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        title = point.pointNameJa
        subtitle = data.text(for: element)
    }
}

// MARK: - AmedasAnnotationView
final class AmedasAnnotationView: MKAnnotationView {
    private let size = CGSize(width: 15, height: 15)
    private let borderColor = UIColor.white
    override var alignmentRectInsets: UIEdgeInsets { .zero }
    
    var point: AmedasPoint?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = true
        displayPriority = .defaultHigh
        collisionMode = .circle

        guard let reuseIdentifier = reuseIdentifier else { return }
        let ary = reuseIdentifier.components(separatedBy: ",")
        if ary.count == 2, ary[0] == AmedasElement.Shape.circle.rawValue, let color = UIColor(hex: ary[1]) {
            drawCircle(color: color)
        } else if ary.count == 3, ary[0] == AmedasElement.Shape.arrow.rawValue,
                  let direction = Int(ary[1]), let color = UIColor(hex: ary[2]) {
            drawArrow(direction: direction, color: color)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 円をを表示に設定
    private func drawCircle(color: UIColor) {
        //LOG(#function + ", color:\(color)")
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
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
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    // 矢羽を表示に設定
    private func drawArrow(direction: Int, color: UIColor) {
        if direction == 0 {
            drawCircle(color: color)
            return
        }
        guard direction > 0, direction <= 16 else { return }
        
        //LOG(#function + ", direction:\(direction), color:\(color)")
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let rect = CGRect(origin: .zero, size: size)

        // 色を指定
        context.setFillColor(color.cgColor)
        context.setStrokeColor(borderColor.cgColor)
        
        // 矢羽を描画
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY - 1.0))
        path.addLine(to: CGPoint(x: rect.midX + 5.0, y: rect.midY - 5.0))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY + 7.0))
        path.addLine(to: CGPoint(x: rect.midX - 5.0, y: rect.midY - 5.0))
        path.close()
        
        // 方角にあわせて回転
        let rotation: CGFloat = 2 * .pi * CGFloat(direction) / 16
        path.apply(CGAffineTransform(translationX: -rect.midX, y: -rect.midY))
        path.apply(CGAffineTransform(rotationAngle: rotation))
        path.apply(CGAffineTransform(translationX: rect.midX, y: rect.midY))
        
        path.stroke()
        path.fill()

        // 画像を出力
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}
