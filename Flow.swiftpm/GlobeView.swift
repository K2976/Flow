import SwiftUI
import SceneKit

#if os(macOS)
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
#endif

// MARK: - Globe Scene View

struct GlobeSceneView: PlatformViewRepresentable {
    let score: Double

    #if os(macOS)
    func makeNSView(context: Context) -> GlobePlanetView {
        let v = GlobePlanetView()
        v.setupScene(score: score)
        return v
    }

    func updateNSView(_ nsView: GlobePlanetView, context: Context) {
        nsView.updateScore(score)
    }
    #else
    func makeUIView(context: Context) -> GlobePlanetView {
        let v = GlobePlanetView()
        v.setupScene(score: score)
        return v
    }

    func updateUIView(_ uiView: GlobePlanetView, context: Context) {
        uiView.updateScore(score)
    }
    #endif

    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator {}
}

// MARK: - Custom SCNView with Mouse Interaction

@MainActor
final class GlobePlanetView: SCNView {

    // MARK: Nodes
    private var planetNode: SCNNode!
    private var planetMaterial: SCNMaterial!
    private var lastAppliedScore: Double = -1

    // MARK: Rotation state
    private var orientation = simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
    private let autoYawRate: Float = Float(.pi * 2 / 90.0)

    // Drag state
    private var dragging = false
    private var lastDragPt: CGPoint = .zero
    private var lastDragTS: TimeInterval = 0
    private var velYaw:   Float = 0
    private var velPitch: Float = 0

    // Frame loop
    private var frameTimer: Timer?
    private var lastTick:   CFTimeInterval = 0

    // MARK: – Setup ────────────────────────────────────────────────────────────

    func setupScene(score: Double) {
        antialiasingMode    = .multisampling4X
        allowsCameraControl = false
        showsStatistics     = false
        backgroundColor     = .clear

        let scene = SCNScene()
        scene.background.contents = PlatformColor.clear
        self.scene = scene

        addCamera(to: scene)
        addLights(to: scene)
        addPlanet(to: scene, score: score)
        startLoop()
    }

    // MARK: – Score Update ─────────────────────────────────────────────────────

    func updateScore(_ score: Double) {
        guard abs(score - lastAppliedScore) > 1.0 else { return }
        lastAppliedScore = score
        
        let targetColor = FlowColors.color(for: score)
        #if os(macOS)
        let resolved = PlatformColor(targetColor).usingColorSpace(.deviceRGB) ?? PlatformColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 1)
        #else
        let resolved = PlatformColor(targetColor)
        #endif
        
        // Transition colors for nodes and arcs
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0 // Smooth color transition
        
        planetNode?.childNodes.forEach { node in
            if node.name == "dot" || node.name == "activeDot" {
                node.geometry?.firstMaterial?.diffuse.contents = resolved
                node.geometry?.firstMaterial?.emission.contents = resolved
            } else if node.name == "arc" {
                node.geometry?.firstMaterial?.diffuse.contents = resolved.withAlphaComponent(0.6)
                node.geometry?.firstMaterial?.emission.contents = resolved.withAlphaComponent(0.4)
            }
        }
        
        SCNTransaction.commit()
    }

    // MARK: – Scene Building ───────────────────────────────────────────────────

    private func addCamera(to scene: SCNScene) {
        let cam = SCNCamera()
        cam.fieldOfView = 38
        cam.zNear = 0.1
        cam.zFar  = 100
        
        // Perspective adjustment aids in depth feel
        let node = SCNNode()
        node.camera   = cam
        node.position = SCNVector3(0, 0, 5.5)
        scene.rootNode.addChildNode(node)
    }

    private func addLights(to scene: SCNScene) {
        let amb = SCNNode()
        amb.light           = SCNLight()
        amb.light!.type      = .ambient
        // Increase ambient slightly so nodes don't go entirely black on back half
        amb.light!.intensity = 350
        amb.light!.color     = PlatformColor.white
        scene.rootNode.addChildNode(amb)

        let main = SCNNode()
        main.light           = SCNLight()
        main.light!.type      = .directional
        main.light!.intensity = 600
        main.light!.color     = PlatformColor(white: 0.85, alpha: 1)
        main.eulerAngles      = SCNVector3(-0.6, -0.8, 0)
        scene.rootNode.addChildNode(main)
    }

    private func addPlanet(to scene: SCNScene, score: Double) {
        planetNode = SCNNode()
        
        let currentSwiftColor = FlowColors.color(for: score)
        #if os(macOS)
        let resolved = PlatformColor(currentSwiftColor).usingColorSpace(.deviceRGB) ?? PlatformColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 1)
        #else
        let resolved = PlatformColor(currentSwiftColor)
        #endif
        
        let numDots = 250 // Amount of nodes for the point cloud
        let radius: Float = 1.05 // Slightly larger than the old 1.0 solid orb to feel voluminous
        
        let goldenRatio = (1.0 + sqrt(5.0)) / 2.0
        
        var points: [SCNVector3] = []
        
        // 1. Generate Fibonacci Lattice wrapping a sphere
        for i in 0..<numDots {
            let theta = 2.0 * Float.pi * Float(i) / Float(goldenRatio)
            let phi = acos(1.0 - 2.0 * (Float(i) + 0.5) / Float(numDots))
            
            // Convert to Cartesian
            let x = radius * sin(phi) * cos(theta)
            let y = radius * sin(phi) * sin(theta)
            let z = radius * cos(phi)
            
            let point = SCNVector3(x, y, z)
            points.append(point)
            
            // Randomly select active nodes to be slightly larger
            let isActive = Float.random(in: 0...1) > 0.95
            
            // Material for dot
            let mat = SCNMaterial()
            mat.diffuse.contents = resolved
            
            // Soft glow
            mat.emission.contents = resolved
            mat.emission.intensity = isActive ? 1.0 : 0.6
            
            // Transparent blending for softer back-side
            mat.transparent.contents = PlatformColor(white: 1.0, alpha: isActive ? 0.95 : 0.7)
            mat.blendMode = .add
            mat.isDoubleSided = false
            
            // Spherical geometry for dots
            let dotRadius: CGFloat = isActive ? 0.025 : 0.015
            let dotGeom = SCNSphere(radius: dotRadius)
            dotGeom.segmentCount = 12 // Low poly ok for small dots
            dotGeom.firstMaterial = mat
            
            let dotNode = SCNNode(geometry: dotGeom)
            dotNode.position = point
            dotNode.name = isActive ? "activeDot" : "dot"
            
            // If active, give it a tiny pulsing animation
            if isActive {
                let scaleUp = SCNAction.scale(to: 1.25, duration: TimeInterval.random(in: 2.5...4.0))
                scaleUp.timingMode = .easeInEaseOut
                let scaleDown = SCNAction.scale(to: 0.9, duration: TimeInterval.random(in: 2.5...4.0))
                scaleDown.timingMode = .easeInEaseOut
                dotNode.runAction(SCNAction.repeatForever(SCNAction.sequence([scaleUp, scaleDown])))
            }
            
            planetNode.addChildNode(dotNode)
        }
        
        // 2. Generate smooth connecting arcs between some neighboring points
        let numArcs = 25
        for _ in 0..<numArcs {
            guard let ptA = points.randomElement(),
                  let ptB = points.randomElement(),
                  distance(ptA, ptB) > 0.2 && distance(ptA, ptB) < 0.6 else { continue }
            
            // Create bezier curve arching out from the sphere's surface slightly
            let midPt = SCNVector3(
                (ptA.x + ptB.x) / 2,
                (ptA.y + ptB.y) / 2,
                (ptA.z + ptB.z) / 2
            )
            
            // Push midpt out radially
            let mx = Float(midPt.x)
            let my = Float(midPt.y)
            let mz = Float(midPt.z)
            let midLen = sqrt(mx*mx + my*my + mz*mz)
            let arcHeight: Float = 1.15 // Peak of the arc
            let elevatedMid = SCNVector3(
                (mx / midLen) * arcHeight,
                (my / midLen) * arcHeight,
                (mz / midLen) * arcHeight
            )
            
            let arcGeom = createArcGeometry(from: ptA, to: ptB, controlPoint: elevatedMid, segments: 16)
            let arcMat = SCNMaterial()
            arcMat.diffuse.contents = resolved.withAlphaComponent(0.6)
            arcMat.emission.contents = resolved.withAlphaComponent(0.4)
            arcMat.transparent.contents = PlatformColor(white: 1.0, alpha: 0.6)
            arcMat.blendMode = .add
            arcGeom.firstMaterial = arcMat
            
            let arcNode = SCNNode(geometry: arcGeom)
            arcNode.name = "arc"
            
            // Pulse the arcs in and out
            let fadeOut = SCNAction.fadeOpacity(to: 0.3, duration: TimeInterval.random(in: 3...5))
            let fadeIn = SCNAction.fadeOpacity(to: 1.0, duration: TimeInterval.random(in: 3...5))
            arcNode.runAction(SCNAction.repeatForever(SCNAction.sequence([fadeOut, fadeIn])))
            arcNode.opacity = CGFloat.random(in: 0.3...1.0)
            
            planetNode.addChildNode(arcNode)
        }
        
        scene.rootNode.addChildNode(planetNode)
        lastAppliedScore = score
    }
    
    // Distance helper
    private func distance(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        let dx = Float(a.x) - Float(b.x)
        let dy = Float(a.y) - Float(b.y)
        let dz = Float(a.z) - Float(b.z)
        
        let dx2 = dx * dx
        let dy2 = dy * dy
        let dz2 = dz * dz
        
        return sqrt(dx2 + dy2 + dz2)
    }
    
    // Build a tubular bezier curve
    private func createArcGeometry(from start: SCNVector3, to end: SCNVector3, controlPoint: SCNVector3, segments: Int) -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var indices: [UInt16] = []
        
        let sides = 4 // Square tube cross-section to keep vertex count low
        let radius: Float = 0.003 // Very thin line
        
        // 1. Generate points along the quadratic bezier
        var pathPoints: [SCNVector3] = []
        for i in 0...segments {
            let t = Float(i) / Float(segments)
            let u = 1.0 - t
            // B(t) = (1-t)^2 * P0 + 2t(1-t) * P1 + t^2 * P2
            let u1 = u * u
            let t1 = 2 * t * u
            let t2 = t * t
            
            let x1 = u1 * Float(start.x)
            let x2 = t1 * Float(controlPoint.x)
            let x3 = t2 * Float(end.x)
            let x = x1 + x2 + x3
            
            let y1 = u1 * Float(start.y)
            let y2 = t1 * Float(controlPoint.y)
            let y3 = t2 * Float(end.y)
            let y = y1 + y2 + y3
            
            let z1 = u1 * Float(start.z)
            let z2 = t1 * Float(controlPoint.z)
            let z3 = t2 * Float(end.z)
            let z = z1 + z2 + z3
            pathPoints.append(SCNVector3(x, y, z))
        }
        
        // 2. Extrude a small cross-section along the path
        for i in 0...segments {
            let pt = pathPoints[i]
            
            // We need a direction vector for the normal plane
            let dir: SCNVector3
            if i < segments {
                let nextPt = pathPoints[i+1]
                dir = SCNVector3(Float(nextPt.x) - Float(pt.x), Float(nextPt.y) - Float(pt.y), Float(nextPt.z) - Float(pt.z))
            } else {
                let prevPt = pathPoints[i-1]
                dir = SCNVector3(Float(pt.x) - Float(prevPt.x), Float(pt.y) - Float(prevPt.y), Float(pt.z) - Float(prevPt.z))
            }
            
            let dx = Float(dir.x)
            let dy = Float(dir.y)
            let dz = Float(dir.z)
            let len = sqrt(dx*dx + dy*dy + dz*dz)
            let fwd = SCNVector3(dx/len, dy/len, dz/len)
            
            // Create orthogonal vectors
            var up = SCNVector3(0, 1, 0)
            if abs(Float(fwd.y)) > 0.99 {
                up = SCNVector3(1, 0, 0)
            }
            
            let uX = Float(up.x); let uY = Float(up.y); let uZ = Float(up.z)
            let fX = Float(fwd.x); let fY = Float(fwd.y); let fZ = Float(fwd.z)
            
            // Cross product
            let right = SCNVector3(uY*fZ - uZ*fY, uZ*fX - uX*fZ, uX*fY - uY*fX)
            let rX = Float(right.x); let rY = Float(right.y); let rZ = Float(right.z)
            let rlen = sqrt(rX*rX + rY*rY + rZ*rZ)
            let nRight = SCNVector3(rX/rlen, rY/rlen, rZ/rlen)
            let nrX = Float(nRight.x); let nrY = Float(nRight.y); let nrZ = Float(nRight.z)
            
            // Re-cross for true up
            let nUpX = fY*nrZ - fZ*nrY
            let nUpY = fZ*nrX - fX*nrZ
            let nUpZ = fX*nrY - fY*nrX
            let nUp = SCNVector3(nUpX, nUpY, nUpZ)
            
            // Generate cross-section vertices
            for s in 0..<sides {
                let angle = Float(s) * 2.0 * Float.pi / Float(sides)
                let c = cos(angle) * radius
                let sAng = sin(angle) * radius
                
                let cX = c * Float(nRight.x)
                let cY = c * Float(nRight.y)
                let cZ = c * Float(nRight.z)
                
                let sX = sAng * Float(nUp.x)
                let sY = sAng * Float(nUp.y)
                let sZ = sAng * Float(nUp.z)
                
                let vx = Float(pt.x) + cX + sX
                let vy = Float(pt.y) + cY + sY
                let vz = Float(pt.z) + cZ + sZ
                
                vertices.append(SCNVector3(vx, vy, vz))
            }
            
            // Generate triangles
            if i > 0 {
                let currRing = i * sides
                let prevRing = (i - 1) * sides
                
                for s in 0..<sides {
                    let nextS = (s + 1) % sides
                    
                    let v0 = UInt16(prevRing + s)
                    let v1 = UInt16(currRing + s)
                    let v2 = UInt16(currRing + nextS)
                    let v3 = UInt16(prevRing + nextS)
                    
                    // Triangle 1
                    indices.append(v0)
                    indices.append(v1)
                    indices.append(v2)
                    
                    // Triangle 2
                    indices.append(v0)
                    indices.append(v2)
                    indices.append(v3)
                }
            }
        }
        
        let src = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        return SCNGeometry(sources: [src], elements: [element])
    }

    // (Texture generator removed for Point Cloud style)

    // MARK: – Frame Loop ───────────────────────────────────────────────────────

    private func startLoop() {
        lastTick = CACurrentMediaTime()
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        RunLoop.main.add(frameTimer!, forMode: .common)
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt  = Float(now - lastTick)
        lastTick = now
        guard dt > 0 && dt < 0.1 else { return }
        if dragging { return }

        let speed = max(abs(velYaw), abs(velPitch))
        if speed > 0.005 {
            let friction: Float = pow(0.88, dt * 60)
            velYaw   *= friction
            velPitch *= friction
            applyDelta(yaw: velYaw * dt, pitch: velPitch * dt)
        } else {
            velYaw   = 0
            velPitch = 0
            
            // Slow down the auto rotation to 120 seconds for full rotation
            // 2PI radians / 120s = 0.0523 rad/s
            let slowRate: Float = Float.pi * 2 / 120.0
            applyDelta(yaw: slowRate * dt, pitch: 0)
        }
    }

    private func applyDelta(yaw: Float, pitch: Float) {
        if yaw != 0 {
            orientation = simd_quatf(angle: yaw, axis: simd_float3(0, 1, 0)) * orientation
        }
        if pitch != 0 {
            orientation = simd_quatf(angle: pitch, axis: simd_float3(1, 0, 0)) * orientation
        }
        planetNode?.simdOrientation = orientation
    }

    // MARK: – Mouse / Touch Events ───────────────────────────────────────────────

    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        let loc  = convert(event.locationInWindow, from: nil)
        dragging   = true
        lastDragPt = loc
        lastDragTS = event.timestamp
        velYaw     = 0
        velPitch   = 0
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragging else { return }
        let loc = convert(event.locationInWindow, from: nil)
        let dx  = Float(loc.x - lastDragPt.x)
        let dy  = Float(loc.y - lastDragPt.y)
        let dt  = Float(max(event.timestamp - lastDragTS, 1.0 / 120.0))
        let sens: Float = 0.007
        applyDelta(yaw: -dx * sens, pitch: dy * sens)
        let a: Float = 0.4
        velYaw   = velYaw   * (1 - a) + (-dx * sens / dt) * a
        velPitch = velPitch * (1 - a) + ( dy * sens / dt) * a
        lastDragPt = loc
        lastDragTS = event.timestamp
        
    }

    override func mouseUp(with event: NSEvent) {
        dragging = false
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            frameTimer?.invalidate()
            frameTimer = nil
        }
    }
    #else
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let hits = hitTest(loc, options: nil)
        guard !hits.isEmpty else { return }
        dragging = true
        lastDragPt = loc
        lastDragTS = event?.timestamp ?? ProcessInfo.processInfo.systemUptime
        velYaw = 0
        velPitch = 0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard dragging, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let dx = Float(loc.x - lastDragPt.x)
        let dy = Float(loc.y - lastDragPt.y)
        let ts = event?.timestamp ?? ProcessInfo.processInfo.systemUptime
        let dt = Float(max(ts - lastDragTS, 1.0 / 120.0))
        let sens: Float = 0.007
        // On iOS, dragging down means dy > 0, which corresponds to positive pitch. Wait, let's just use the same axis.
        applyDelta(yaw: -dx * sens, pitch: dy * sens)
        let a: Float = 0.4
        velYaw   = velYaw   * (1 - a) + (-dx * sens / dt) * a
        velPitch = velPitch * (1 - a) + ( dy * sens / dt) * a
        lastDragPt = loc
        lastDragTS = ts
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragging = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragging = false
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            frameTimer?.invalidate()
            frameTimer = nil
        }
    }
    #endif
}
