//
//  DebugDrawingComparisonView.swift
//

import SwiftUI
import PencilKit

struct DebugDrawingComparisonView: View {
    // Estado do canvas do usuário
    @State private var canvasView = PKCanvasView()
    @State private var userDrawing = PKDrawing()
    
    // Desenho base (SVG)
    @State private var baseDrawing = PKDrawing()
    @State private var baseSVGName = "RuneWeakness" // Altere para o nome do seu SVG
    
    // Métricas de debug
    @State private var currentDistance: CGFloat = 0
    @State private var userPointsCount: Int = 0
    @State private var basePointsCount: Int = 0
    @State private var calculationTime: Double = 0
    
    // Controles de visualização
    @State private var showBaseDrawing = true
    @State private var showPoints = false
    @State private var showNormalizedPoints = false
    @State private var overlayOpacity: Double = 0.5
    
    // Debug avançado
    @State private var debugInfo: DebugMetrics?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // SEÇÃO 1: Canvas de Desenho
                    drawingSection
                    
                    // SEÇÃO 2: Métricas Principais
                    metricsSection
                    
                    // SEÇÃO 3: Visualizações Comparativas
                    visualizationSection
                    
                    // SEÇÃO 4: Debug Detalhado
                    if let debug = debugInfo {
                        debugDetailsSection(debug: debug)
                    }
                    
                    // SEÇÃO 5: Controles
                    controlsSection
                }
                .padding()
            }
            .navigationTitle("Debug - Comparação de Desenhos")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadBaseDrawing()
        }
    }
    
    // MARK: - Drawing Section
    private var drawingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Canvas de Desenho")
                .font(.headline)
            
            ZStack {
                // Canvas do usuário
                CanvasView(canvasView: $canvasView, drawing: $userDrawing, onDrawingChanged: handleDrawingChange)
                    .frame(height: 400)
                    .border(Color.blue, width: 2)
                
                // Overlay do desenho base
                if showBaseDrawing {
                    DrawingOverlayView(drawing: baseDrawing, showPoints: showPoints)
                        .opacity(overlayOpacity)
                        .allowsHitTesting(false)
                }
            }
            
            // Controles do overlay
            HStack {
                Toggle("Mostrar Base", isOn: $showBaseDrawing)
                Spacer()
                if showBaseDrawing {
                    Text("Opacidade: \(Int(overlayOpacity * 100))%")
                        .font(.caption)
                    Slider(value: $overlayOpacity, in: 0...1)
                        .frame(width: 120)
                }
            }
            .font(.caption)
        }
    }
    
    // MARK: - Metrics Section
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Métricas de Comparação")
                .font(.headline)
            
            GroupBox {
                VStack(spacing: 8) {
                    MetricRow(label: "Distância de Fréchet", value: String(format: "%.4f", currentDistance), color: distanceColor)
                    Divider()
                    MetricRow(label: "Pontos no Desenho", value: "\(userPointsCount)", color: .blue)
                    MetricRow(label: "Pontos na Base", value: "\(basePointsCount)", color: .green)
                    Divider()
                    MetricRow(label: "Tempo de Cálculo", value: String(format: "%.2f ms", calculationTime), color: .orange)
                }
            }
        }
    }
    
    // MARK: - Visualization Section
    private var visualizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visualizações")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Desenho do Usuário
                VStack {
                    Text("Seu Desenho")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DrawingPreviewView(drawing: userDrawing, showPoints: showPoints)
                        .frame(height: 150)
                        .border(Color.blue, width: 1)
                }
                
                // Desenho Base
                VStack {
                    Text("Desenho Base")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DrawingPreviewView(drawing: baseDrawing, showPoints: showPoints)
                        .frame(height: 150)
                        .border(Color.green, width: 1)
                }
            }
            
            Toggle("Mostrar Pontos Interpolados", isOn: $showPoints)
                .font(.caption)
            
            if showNormalizedPoints, let debug = debugInfo {
                normalizedPointsVisualization(debug: debug)
            }
        }
    }
    
    // MARK: - Debug Details Section
    private func debugDetailsSection(debug: DebugMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informações de Debug")
                .font(.headline)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    DebugInfoRow(label: "Pontos Brutos (Usuário)", value: "\(debug.userRawPoints)")
                    DebugInfoRow(label: "Pontos Brutos (Base)", value: "\(debug.baseRawPoints)")
                    Divider()
                    DebugInfoRow(label: "Pontos Normalizados (Usuário)", value: "\(debug.userNormalizedPoints)")
                    DebugInfoRow(label: "Pontos Normalizados (Base)", value: "\(debug.baseNormalizedPoints)")
                    Divider()
                    DebugInfoRow(label: "Centroide Usuário", value: "(\(String(format: "%.2f", debug.userCentroid.x)), \(String(format: "%.2f", debug.userCentroid.y)))")
                    DebugInfoRow(label: "Centroide Base", value: "(\(String(format: "%.2f", debug.baseCentroid.x)), \(String(format: "%.2f", debug.baseCentroid.y)))")
                    Divider()
                    DebugInfoRow(label: "Escala Usuário", value: String(format: "%.4f", debug.userScale))
                    DebugInfoRow(label: "Escala Base", value: String(format: "%.4f", debug.baseScale))
                    Divider()
                    DebugInfoRow(label: "Distância Normal", value: String(format: "%.4f", debug.normalDistance))
                    DebugInfoRow(label: "Distância Invertida", value: String(format: "%.4f", debug.flippedDistance))
                    DebugInfoRow(label: "Distância Final (mínima)", value: String(format: "%.4f", debug.finalDistance), highlight: true)
                }
            }
            
            Toggle("Mostrar Pontos Normalizados", isOn: $showNormalizedPoints)
                .font(.caption)
        }
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: clearDrawing) {
                    Label("Limpar Desenho", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: recalculate) {
                    Label("Recalcular", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Seletor de desenho base
            HStack {
                Text("SVG Base:")
                    .font(.caption)
                TextField("Nome do SVG", text: $baseSVGName)
                    .textFieldStyle(.roundedBorder)
                Button("Carregar") {
                    loadBaseDrawing()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Normalized Points Visualization
    private func normalizedPointsVisualization(debug: DebugMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pontos Normalizados (Sobrepostos)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let scale = size / 2
                let center = CGPoint(x: size / 2, y: size / 2)
                
                ZStack {
                    // Grade de referência
                    Path { path in
                        path.move(to: CGPoint(x: center.x, y: 0))
                        path.addLine(to: CGPoint(x: center.x, y: size))
                        path.move(to: CGPoint(x: 0, y: center.y))
                        path.addLine(to: CGPoint(x: size, y: center.y))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    
                    // Pontos do usuário (azul)
                    ForEach(Array(debug.userNormalizedPointsList.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                            .position(x: center.x + point.x * scale, y: center.y + point.y * scale)
                    }
                    
                    // Pontos da base (verde)
                    ForEach(Array(debug.baseNormalizedPointsList.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                            .position(x: center.x + point.x * scale, y: center.y + point.y * scale)
                    }
                }
            }
            .frame(height: 200)
            .border(Color.gray, width: 1)
            
            HStack {
                Label("Usuário", systemImage: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Spacer()
                Label("Base", systemImage: "circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Helper Views
    private var distanceColor: Color {
        if currentDistance < 0.1 {
            return .green
        } else if currentDistance < 0.3 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Actions
    private func loadBaseDrawing() {
        baseDrawing = SVGToDrawingConverter.convertSVG(named: baseSVGName)
        basePointsCount = baseDrawing.strokes.flatMap {
            $0.path.interpolatedPoints(by: .parametricStep(0.2))
        }.count
        
        if !userDrawing.strokes.isEmpty {
            calculateDistance()
        }
    }
    
    private func handleDrawingChange() {
        userDrawing = canvasView.drawing
        
        if !userDrawing.strokes.isEmpty {
            calculateDistance()
        }
    }
    
    private func calculateDistance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Calcula a distância
        currentDistance = userDrawing.distance(to: baseDrawing)
        
        // Conta os pontos
        userPointsCount = userDrawing.strokes.flatMap {
            $0.path.interpolatedPoints(by: .parametricStep(0.2))
        }.count
        
        // Calcula o tempo
        calculationTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        // Gera métricas de debug detalhadas
        debugInfo = generateDebugMetrics()
    }
    
    private func generateDebugMetrics() -> DebugMetrics {
        // Extrai pontos brutos
        let userPointsRaw = userDrawing.strokes.flatMap { stroke in
            stroke.path.interpolatedPoints(by: .parametricStep(0.2)).map { $0.location.applying(stroke.transform) }
        }
        
        let basePointsRaw = baseDrawing.strokes.flatMap { stroke in
            stroke.path.interpolatedPoints(by: .parametricStep(0.2)).map { $0.location.applying(stroke.transform) }
        }
        
        // Normaliza
        let (userNormalized, userCentroid, userScale) = normalizePoints(userPointsRaw)
        let (baseNormalized, baseCentroid, baseScale) = normalizePoints(basePointsRaw)
        
        // Calcula ambas as distâncias
        let normalDist = frechetDistance(userNormalized, baseNormalized)
        let flippedDist = frechetDistance(userNormalized, baseNormalized.reversed())
        
        return DebugMetrics(
            userRawPoints: userPointsRaw.count,
            baseRawPoints: basePointsRaw.count,
            userNormalizedPoints: userNormalized.count,
            baseNormalizedPoints: baseNormalized.count,
            userCentroid: userCentroid,
            baseCentroid: baseCentroid,
            userScale: userScale,
            baseScale: baseScale,
            normalDistance: normalDist,
            flippedDistance: flippedDist,
            finalDistance: min(normalDist, flippedDist),
            userNormalizedPointsList: userNormalized,
            baseNormalizedPointsList: baseNormalized
        )
    }
    
    private func normalizePoints(_ points: [CGPoint]) -> ([CGPoint], CGPoint, CGFloat) {
        guard !points.isEmpty else { return ([], .zero, 1) }
        
        let centroid = CGPoint(
            x: points.map { $0.x }.reduce(0, +) / CGFloat(points.count),
            y: points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        )
        
        let centered = points.map { CGPoint(x: $0.x - centroid.x, y: $0.y - centroid.y) }
        
        let maxX = centered.map { abs($0.x) }.max() ?? 1
        let maxY = centered.map { abs($0.y) }.max() ?? 1
        let scale = max(maxX, maxY)
        
        let normalized = centered.map { CGPoint(x: $0.x / scale, y: $0.y / scale) }
        
        return (normalized, centroid, scale)
    }
    
    private func frechetDistance(_ A: [CGPoint], _ B: [CGPoint]) -> CGFloat {
        let m = A.count
        let n = B.count
        guard m > 0 && n > 0 else { return .greatestFiniteMagnitude }
        
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
    
    private func clearDrawing() {
        userDrawing = PKDrawing()
        canvasView.drawing = PKDrawing()
        currentDistance = 0
        userPointsCount = 0
        calculationTime = 0
        debugInfo = nil
    }
    
    private func recalculate() {
        if !userDrawing.strokes.isEmpty {
            calculateDistance()
        }
    }
}

// MARK: - Supporting Views

struct MetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(color)
                .fontWeight(.bold)
        }
    }
}

struct DebugInfoRow: View {
    let label: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(highlight ? .bold : .regular)
                .foregroundColor(highlight ? .blue : .primary)
        }
    }
}

// MARK: - Data Models

struct DebugMetrics {
    let userRawPoints: Int
    let baseRawPoints: Int
    let userNormalizedPoints: Int
    let baseNormalizedPoints: Int
    let userCentroid: CGPoint
    let baseCentroid: CGPoint
    let userScale: CGFloat
    let baseScale: CGFloat
    let normalDistance: CGFloat
    let flippedDistance: CGFloat
    let finalDistance: CGFloat
    let userNormalizedPointsList: [CGPoint]
    let baseNormalizedPointsList: [CGPoint]
}

#Preview {
    DebugDrawingComparisonView()
}


// MARK: RESUMO ALGORITMO
/*
 1 - Carrega o SVG que representa o desenho base (procura primeiro em Resources/Paths, depois em paths e, por ultimo, no diretorio raiz. Se não encontrar, devolve um PKDrawing vazio)
 2 - Converte o SVG carregado no passo 1 para um PKDrawing, com apenas um stroke
    - Nesse passo, ocorre a normalização do SVG, mantendo a proporção do desenho original de acordo com o canvas
    - Também é calculado um offset, para garantir que o desenho fique centralizado no canvas
 3 -
 */
