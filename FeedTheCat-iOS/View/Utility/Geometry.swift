//
//  Trigonometry.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 17/08/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import UIKit

enum Geometry {
    static func distance(between pointA: CGPoint, and pointB: CGPoint) -> CGFloat {
        let dx = Float(pointA.x - pointB.x), dy = Float(pointA.y - pointB.y)
        return CGFloat(sqrtf(dx*dx + dy*dy))
    }

    static func angle(for point: CGPoint, with center: CGPoint) -> CGFloat {
        var angle = CGFloat(-atan2f(Float(point.x - center.x), Float(point.y - center.y))) + .pi/2
        if (angle < 0) {
            angle += .pi*2;
        }
        return angle
    }

    static func angle(between pointA: CGPoint, and pointB: CGPoint, with center: CGPoint) -> CGFloat {
        return angle(for: pointB, with: center) - angle(for: pointA, with: center)
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: origin.x + size.width/2, y: origin.y + size.height/2)
    }
}
