import CoreGraphics

extension CGPath {
    func getInterpolatedPoints(maxPoints: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        
        self.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            switch element.type {
            case .moveToPoint:
                points.append(element.points[0])
                
            case .addLineToPoint:
                let from = points.last ?? .zero
                let to = element.points[0]
                
                // CRÍTICO: Adicionar pontos intermediários para FORÇAR linha reta
                let distance = hypot(to.x - from.x, to.y - from.y)
                let numPoints = max(Int(distance / 100), 2) // Um ponto a cada 5 unidades
                
                for i in 1...numPoints {
                    let t = CGFloat(i) / CGFloat(numPoints)
                    let x = from.x + (to.x - from.x) * t
                    let y = from.y + (to.y - from.y) * t
                    points.append(CGPoint(x: x, y: y))
                }
                
            case .addQuadCurveToPoint:
                let from = points.last ?? .zero
                let control = element.points[0]
                let to = element.points[1]
                for t in stride(from: 0.0, through: 1.0, by: 1.0 / Double(maxPoints)) {
                    let t = CGFloat(t)
                    let x = pow(1 - t, 2) * from.x + 2 * (1 - t) * t * control.x + pow(t, 2) * to.x
                    let y = pow(1 - t, 2) * from.y + 2 * (1 - t) * t * control.y + pow(t, 2) * to.y
                    points.append(CGPoint(x: x, y: y))
                }
            case .addCurveToPoint:
                let from = points.last ?? .zero
                let c1 = element.points[0]
                let c2 = element.points[1]
                let to = element.points[2]
                
                // MELHORIA: Verificar se é uma linha reta disfarçada de curva
                if isLinear(from: from, c1: c1, c2: c2, to: to) {
                    // Tratar como linha reta
                    let numPoints = 10
                    for i in 1...numPoints {
                        let t = CGFloat(i) / CGFloat(numPoints)
                        let x = from.x + (to.x - from.x) * t
                        let y = from.y + (to.y - from.y) * t
                        points.append(CGPoint(x: x, y: y))
                    }
                } else {
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
                }
                
            default:
                break
            }
        }
        
        return points
    }
    
    // Função auxiliar para detectar curvas que são na verdade linhas retas
    private func isLinear(from: CGPoint, c1: CGPoint, c2: CGPoint, to: CGPoint) -> Bool {
        // Calcula a distância dos pontos de controle à linha reta from->to
        func distanceToLine(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
            let num = abs((lineEnd.y - lineStart.y) * point.x - (lineEnd.x - lineStart.x) * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
            let den = hypot(lineEnd.y - lineStart.y, lineEnd.x - lineStart.x)
            return num / den
        }
        
        let threshold: CGFloat = 1.0 // Tolerância
        return distanceToLine(point: c1, lineStart: from, lineEnd: to) < threshold &&
               distanceToLine(point: c2, lineStart: from, lineEnd: to) < threshold
    }
}
