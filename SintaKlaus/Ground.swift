//
//  Ground.swift
//  SintaKlaus
//
//  Created by Jacob Edwards on 13/11/2024.
//

import SwiftUI

extension SIMD3 where Scalar == Float {
    var grounded : SIMD3<Scalar> {
        return .init(x: x, y: 0, z: z)
    }
}
