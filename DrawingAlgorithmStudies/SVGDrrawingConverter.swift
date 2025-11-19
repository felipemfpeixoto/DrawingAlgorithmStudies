import PencilKit
import PocketSVG

/// Converte um SVG (por nome de arquivo) em um PKDrawing simplificado.
/// Procura o arquivo em Resources/Paths, Paths e raiz do bundle.
class SVGToDrawingConverter {
    /// Converte o SVG em traços aproximados para comparação/calculo de distância.
    /// - Parameter name: nome do arquivo SVG sem extensão
    /// - Returns: PKDrawing com strokes aproximados
    static func convertSVG(named name: String) -> PKDrawing {
        // Tenta resolver o recurso em diferentes subdiretórios, para suportar
        // reorganizações de pastas (ex.: Resources/Paths ou Paths na raiz).
        let subdirs: [String?] = ["Resources/Paths", "Paths", nil]
        var resolvedURL: URL? = nil
        for sub in subdirs {
            if let u = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: sub) {
                resolvedURL = u
                break
            }
        }
        guard let url = resolvedURL else {
            print("SVG não encontrado: \(name)")
            return PKDrawing()
        }

        let svgPaths = SVGBezierPath.pathsFromSVG(at: url)
        print("SVG carregado com \(svgPaths.count) paths")

        // Checa se há pelo menos um path válido
        guard !svgPaths.isEmpty else {
            print("Nenhum path válido encontrado no SVG.")
            return PKDrawing()
        }

        let combinedBounds = svgPaths.reduce(CGRect.null) { $0.union($1.bounds) }
        let canvasSize = CGSize(width: 200, height: 200)
        let scaleFactor = min(canvasSize.width / combinedBounds.width, canvasSize.height / combinedBounds.height) * 0.9 // MARK: Fator de escala que irá aumentar o desenho de acordo com o tamanho do canvas, mantendo a proporção do desenho
        let offset = CGPoint( // MARK: Offset calculado para manter o desenho centralizado no canvas
            x: (canvasSize.width - combinedBounds.width * scaleFactor) / 2 - combinedBounds.origin.x * scaleFactor,
            y: (canvasSize.height - combinedBounds.height * scaleFactor) / 2 - combinedBounds.origin.y * scaleFactor
        )

        let strokes: [PKStroke] = svgPaths.compactMap { path in
            var transform = CGAffineTransform(translationX: offset.x, y: offset.y) // MARK: Move o desenho para a posição correta de acordo com o offset calculado
            transform = transform.scaledBy(x: scaleFactor, y: scaleFactor) // MARK: Aumenta (ou diminui) o desenho de acordo com o fator de escala calculado anteriormente

            guard let transformedPath = path.cgPath.copy(using: &transform) else { // MARK: Aplica a transformação
                print("Erro ao transformar path.")
                return nil
            }

            let points = transformedPath.getInterpolatedPoints(maxPoints: 100) // MARK: (!) Parte crucial, converter a curva em pontos
            guard !points.isEmpty else {
                print("Path transformado não gerou pontos.")
                return nil
            }

            let strokePoints = points.map { // MARK: Define os pontos interpolados definidos no passo anterior PKStrokePoints
                PKStrokePoint(location: $0, timeOffset: 0,
                              size: CGSize(width: 5, height: 5),
                              opacity: 1, force: 1,
                              azimuth: .zero, altitude: .pi/2)
            }

            return PKStroke( // MARK: Cria o PKStroke de acordo com PKStrokePoints criados no passo anterior
                ink: PKInk(.pen, color: .gray),
                path: PKStrokePath(controlPoints: strokePoints, creationDate: Date())
            )
        }

        return PKDrawing(strokes: strokes)
    }
}
