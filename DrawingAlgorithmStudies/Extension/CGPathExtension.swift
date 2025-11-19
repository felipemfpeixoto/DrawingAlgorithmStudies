import CoreGraphics

extension CGPath {
    // MARK: Essa é uma das partes mais importantes do algoritmo. Curvas de Bezier são contínuas, mas precisamos de pontos discretos para depois fazer a comparação
    func getInterpolatedPoints(maxPoints: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        
        var move = 0
        var quadCurve = 0
        var curve = 0

        self.applyWithBlock { elementPointer in // MARK: Percorre cada comando do path (Existem 4: moveToPoint, addLineToPoint, addQuadCurveToPoint e addCurveToPoint)
            let element = elementPointer.pointee
            switch element.type {
            case .moveToPoint, .addLineToPoint: // MARK: Para linhas retas, simplesmente adiciona o ponto final (TALVEZ AQUI SEJA UM PONTO DE ATENÇÃO)
                move += 1
                points.append(element.points[0])
            case .addQuadCurveToPoint: // MARK: Interpolação de curvar quadráticas
                let from = points.last ?? .zero
                let control = element.points[0]
                let to = element.points[1]
                for t in stride(from: 0.0, through: 1.0, by: 1.0 / Double(maxPoints)) {
                    let t = CGFloat(t)
                    let x = pow(1 - t, 2) * from.x + 2 * (1 - t) * t * control.x + pow(t, 2) * to.x
                    let y = pow(1 - t, 2) * from.y + 2 * (1 - t) * t * control.y + pow(t, 2) * to.y
                    points.append(CGPoint(x: x, y: y))
                }
                quadCurve += 1
            case .addCurveToPoint:
                let from = points.last ?? .zero
                let c1 = element.points[0]
                let c2 = element.points[1]
                let to = element.points[2]
                for t in stride(from: 0.0, through: 1.0, by: 1.0 / Double(maxPoints)) {
                    let t = CGFloat(t)
                    let x = pow(1 - t, 3) * from.x
                          + 3 * pow(1 - t, 2) * t * c1.x
                          + 3 * (1 - t) * pow(t, 2) * c2.x
                          + pow(t, 3) * to.x
                    let y = pow(1 - t, 3) * from.y
                          + 3 * pow(1 - t, 2) * t * c1.y
                          + 3 * (1 - t) * pow(t, 2) * c2.y
                          + pow(t, 3) * to.y
                    points.append(CGPoint(x: x, y: y))
                }
                curve += 1
            default:
                break
            }
        }
        
        print("moves: \(move)")
        print("quadCurves: \(quadCurve)")
        print("curves: \(curve)")

        return points
    }
}
