//
//  CGPointExtensions.swift
//  DuckademyIOS
//
//  Created by Felipe on 09/04/25.
//

import Foundation

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
