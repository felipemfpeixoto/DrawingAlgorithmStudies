import PencilKit
import CoreGraphics

extension PKDrawing {
    func distance(to other: PKDrawing) -> CGFloat {
        // Interpolação dos pontos
        let selfPointsRaw = self.strokes.flatMap { stroke in
            stroke.path.interpolatedPoints(by: .parametricStep(0.2)).map { $0.location.applying(stroke.transform) }
        }

        let otherPointsRaw = other.strokes.flatMap { stroke in
            stroke.path.interpolatedPoints(by: .parametricStep(0.2)).map { $0.location.applying(stroke.transform) }
        }

        guard !selfPointsRaw.isEmpty && !otherPointsRaw.isEmpty else {
            return .greatestFiniteMagnitude
        }

        // Função para centralizar os pontos (normalização por posição)
        func normalizePositionAndScale(_ points: [CGPoint]) -> [CGPoint] {
            guard !points.isEmpty else { return [] }

            // Centraliza
            let centroid = CGPoint(
                x: points.map { $0.x }.reduce(0, +) / CGFloat(points.count),
                y: points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
            )
            let centered = points.map { CGPoint(x: $0.x - centroid.x, y: $0.y - centroid.y) }

            // Calcula escala
            let maxX = centered.map { abs($0.x) }.max() ?? 1
            let maxY = centered.map { abs($0.y) }.max() ?? 1
            let scale = max(maxX, maxY)

            return centered.map { CGPoint(x: $0.x / scale, y: $0.y / scale) }
        }

        let selfPoints = normalizePositionAndScale(selfPointsRaw)
        let otherPoints = normalizePositionAndScale(otherPointsRaw)

        // Calcula a distância de Fréchet
        func frechetDistance(_ A: [CGPoint], _ B: [CGPoint]) -> CGFloat {
            let m = A.count
            let n = B.count
            var ca = Array(repeating: Array(repeating: -1.0 as CGFloat, count: n), count: m)

            for i in 0..<m {
                for j in 0..<n {
                    let d = A[i].distance(to: B[j])
                    if i == 0 && j == 0 {
                        ca[i][j] = d
                    } else if i == 0 {
                        ca[i][j] = max(ca[i][j - 1], d)
                    } else if j == 0 {
                        ca[i][j] = max(ca[i - 1][j], d)
                    } else {
                        ca[i][j] = max(
                            min(ca[i - 1][j], ca[i - 1][j - 1], ca[i][j - 1]),
                            d
                        )
                    }
                }
            }

            return ca[m - 1][n - 1]
        }

        // Testa o vetor normal e o invertido (espelhado na ordem dos pontos)
        let distanceNormal = frechetDistance(selfPoints, otherPoints)
        let distanceFlipped = frechetDistance(selfPoints, otherPoints.reversed())

        return min(distanceNormal, distanceFlipped)
    }
    
    func distance(points: [CGPoint]) -> CGFloat {
        // Interpolação dos pontos
        let selfPointsRaw = self.strokes.flatMap { stroke in
            stroke.path.interpolatedPoints(by: .parametricStep(0.2)).map { $0.location.applying(stroke.transform) }
        }

        let otherPointsRaw = points

        guard !selfPointsRaw.isEmpty && !otherPointsRaw.isEmpty else {
            return .greatestFiniteMagnitude
        }

        // Função para centralizar os pontos (normalização por posição)
        func normalizePositionAndScale(_ points: [CGPoint]) -> [CGPoint] {
            guard !points.isEmpty else { return [] }

            // Centraliza
            let centroid = CGPoint(
                x: points.map { $0.x }.reduce(0, +) / CGFloat(points.count),
                y: points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
            )
            let centered = points.map { CGPoint(x: $0.x - centroid.x, y: $0.y - centroid.y) }

            // Calcula escala
            let maxX = centered.map { abs($0.x) }.max() ?? 1
            let maxY = centered.map { abs($0.y) }.max() ?? 1
            let scale = max(maxX, maxY)

            return centered.map { CGPoint(x: $0.x / scale, y: $0.y / scale) }
        }


        let selfPoints = normalizePositionAndScale(selfPointsRaw)
        let otherPoints = normalizePositionAndScale(otherPointsRaw)

        // Calcula a distância de Fréchet
        func frechetDistance(_ A: [CGPoint], _ B: [CGPoint]) -> CGFloat {
            let m = A.count
            let n = B.count
            var ca = Array(repeating: Array(repeating: -1.0 as CGFloat, count: n), count: m)

            for i in 0..<m {
                for j in 0..<n {
                    let d = A[i].distance(to: B[j])
                    if i == 0 && j == 0 {
                        ca[i][j] = d
                    } else if i == 0 {
                        ca[i][j] = max(ca[i][j - 1], d)
                    } else if j == 0 {
                        ca[i][j] = max(ca[i - 1][j], d)
                    } else {
                        ca[i][j] = max(
                            min(ca[i - 1][j], ca[i - 1][j - 1], ca[i][j - 1]),
                            d
                        )
                    }
                }
            }

            return ca[m - 1][n - 1]
        }

        // Testa o vetor normal e o invertido (espelhado na ordem dos pontos)
        let distanceNormal = frechetDistance(selfPoints, otherPoints)
        let distanceFlipped = frechetDistance(selfPoints, otherPoints.reversed())

        return min(distanceNormal, distanceFlipped)
    }
}
