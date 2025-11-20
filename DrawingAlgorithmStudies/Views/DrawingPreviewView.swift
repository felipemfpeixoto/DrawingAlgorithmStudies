//
//  DrawingPreviewView.swift
//

import SwiftUI
import PencilKit

struct DrawingPreviewView: View {
    let drawing: PKDrawing
    let showPoints: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                
                // Renderiza o desenho
                Image(uiImage: drawing.image(from: drawing.bounds, scale: 1.0))
                    .resizable()
                    .scaledToFit()
                
                // Mostra os pontos se ativado
                if showPoints {
                    let points = drawing.strokes.flatMap { stroke in
                        stroke.path.interpolatedPoints(by: .parametricStep(0.2))
                            .map { $0.location.applying(stroke.transform) }
                    }
                    
                    let bounds = drawing.bounds
                    let scale = min(
                        geometry.size.width / bounds.width,
                        geometry.size.height / bounds.height
                    ) * 0.9
                    
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(Color.red)
                            .frame(width: 3, height: 3)
                            .position(
                                x: (point.x - bounds.minX) * scale + (geometry.size.width - bounds.width * scale) / 2,
                                y: (point.y - bounds.minY) * scale + (geometry.size.height - bounds.height * scale) / 2
                            )
                    }
                }
            }
        }
    }
}

struct DrawingOverlayView: View {
    let drawing: PKDrawing
    let showPoints: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Renderiza o desenho base em verde
                Image(uiImage: drawing.image(from: drawing.bounds, scale: 1.0))
                    .resizable()
                    .scaledToFit()
                    .colorMultiply(.green)
                
                // Pontos do desenho base
                if showPoints {
                    let points = drawing.strokes.flatMap { stroke in
                        stroke.path.interpolatedPoints(by: .parametricStep(0.2))
                            .map { $0.location.applying(stroke.transform) }
                    }
                    
                    let bounds = drawing.bounds
                    let scale = min(
                        geometry.size.width / bounds.width,
                        geometry.size.height / bounds.height
                    ) * 0.9
                    
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(Color.red)
                            .frame(width: 3, height: 3)
                            .position(
                                x: (point.x - bounds.minX) * scale + (geometry.size.width - bounds.width * scale) / 2,
                                y: (point.y - bounds.minY) * scale + (geometry.size.height - bounds.height * scale) / 2
                            )
                    }
                }
            }
        }
    }
}
