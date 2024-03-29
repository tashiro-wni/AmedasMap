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
        case .temperature, .precipitation, .sun, .humidity, .pressure, .snow:
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
        .precipitation: [ "#C0C0C0", "#E0E0E0", "#9AEBFF", "#48E1FF", "#25AEFF",
                          "#00F42E", "#FAF714", "#FF6666", "#E00000", ],
        .wind:          [ "#999999", "#002CB2", "#5FB235", "#FFBF00", "#FF7F00", "#D90000" ],
        .sun:           [ "#999999", "#FFFF00", "#FFA500" ],
        .humidity:      [ "#999999", "#45A3E5", "#002CB2" ],
        .pressure:      [ "#999999" ],
        .snow:          [ "#FAFAFA", "#E6E6E6", "#AAAAAA", "#8C8C8C",
                          "#5777B0", "#2A5DB7", "#8955B3", "#6410AA" ]]

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
    
    // アイコンの描画色を決定
    private func iconColor(for element: AmedasElement) -> ColorString? {
        guard let colors = Self.elementColors[element] else {
            fatalError("colors not defined for \(element)")
        }

        let colorIndex: Int
        
        switch element {
        case .temperature:
            guard let temperature else { return nil }
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
            return colors[colorIndex]

        case .precipitation:
            guard let precipitation1h else { return nil }
            switch precipitation1h {
            case 99 ... 500:  colorIndex = 8
            case 64 ..<  99:  colorIndex = 7
            case 32 ..<  64:  colorIndex = 6
            case 16 ..<  32:  colorIndex = 5
            case  8 ..<  16:  colorIndex = 4
            case  4 ..<   8:  colorIndex = 3
            case  2 ..<   4:  colorIndex = 2
            case  1 ..<   2:  colorIndex = 1
            case  0 ..<   1:  colorIndex = 0
            default:  return nil
            }
            return colors[colorIndex]

        case .wind:
            guard let windSpeed else { return nil }
            switch windSpeed {
            case 25 ... 99:  colorIndex = 5
            case 20 ..< 25:  colorIndex = 4
            case 15 ..< 20:  colorIndex = 3
            case 10 ..< 15:  colorIndex = 2
            case  5 ..< 10:  colorIndex = 1
            case  0 ..<  5:  colorIndex = 0
            default:  return nil
            }
            return colors[colorIndex]
            
        case .sun:
            guard let sun1h else { return nil }
            switch sun1h * 60 {
            case 40 ... 60:  colorIndex = 2
            case 20 ..< 40:  colorIndex = 1
            case  0 ..< 20:  colorIndex = 0
            default: return nil
            }
            return colors[colorIndex]
            
        case .humidity:
            guard let humidity else { return nil }
            switch humidity {
            case 75 ... 100:  colorIndex = 2
            case 50 ..<  75:  colorIndex = 1
            case  0 ..<  50:  colorIndex = 0
            default:  return nil
            }
            return colors[colorIndex]
            
        case .pressure:
            guard pressure != nil else { return nil }
            return colors[0]
            
        case .snow:
            guard let snow else { return nil }
            switch snow {
            case 300 ... 2000:  colorIndex = 7
            case 200 ..<  300:  colorIndex = 6
            case 150 ..<  200:  colorIndex = 5
            case 100 ..<  150:  colorIndex = 4
            case  50 ..<  100:  colorIndex = 3
            case  20 ..<   50:  colorIndex = 2
            case   5 ..<   20:  colorIndex = 1
            case   0 ..<    5:  colorIndex = 0
            default:  return nil
            }
            return colors[colorIndex]
        }
    }

    // AmedasAnnotationView で使用
    func reuseIdentifier(for element: AmedasElement) -> String? {
        guard let colorString = iconColor(for: element) else { return nil }
        
        switch element.iconShape {
        case .circle:
            return [ element.iconShape.rawValue, colorString ]
                .joined(separator: ",")
        case .arrow:
            guard let windDirection else { return nil }
            return [ element.iconShape.rawValue, String(windDirection), colorString ]
                .joined(separator: ",")
        }
    }
    
    // MapView2 で使用
    func makeIcon(for element: AmedasElement) -> UIImage? {
        guard let colorString = iconColor(for: element),
              let color = UIColor(hex: colorString) else { return nil }
        
        switch element.iconShape {
        case .circle:
            return IconHelper.drawCircle(color: color)
        case .arrow:
            guard let windDirection else { return nil }
            return IconHelper.drawArrow(direction: windDirection, color: color)
        }
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
    override var alignmentRectInsets: UIEdgeInsets { .zero }
    
    var point: AmedasPoint?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = true
        displayPriority = .defaultHigh
        collisionMode = .circle
        rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

        guard let reuseIdentifier else { return }
        let ary = reuseIdentifier.components(separatedBy: ",")
        if ary.count == 2, ary[0] == AmedasElement.Shape.circle.rawValue, let color = UIColor(hex: ary[1]) {
            image = IconHelper.drawCircle(color: color)
        } else if ary.count == 3, ary[0] == AmedasElement.Shape.arrow.rawValue,
                  let direction = Int(ary[1]), let color = UIColor(hex: ary[2]) {
            image = IconHelper.drawArrow(direction: direction, color: color)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
