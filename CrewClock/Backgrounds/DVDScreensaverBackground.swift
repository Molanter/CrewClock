import SwiftUI

struct DVDScreensaverBackground: View {
    var image: Image? = nil
    var logoSize: CGSize = .init(width: 140, height: 90)
    var speed: CGFloat = 180
    var background: Color = .black
    var cornerFlashDuration: TimeInterval = 0.20

    /// Use `.animation` for previews to avoid instability.
    var useAnimationSchedule: Bool = false

    @State private var pos: CGPoint = .zero
    @State private var dir: CGVector = .init(dx: 0.7, dy: 0.7)
    @State private var hue: Double = .random(in: 0...1)
    @State private var lastTick: Date = .distantPast
    @State private var seeded = false
    @State private var cornerFlashUntil: Date = .distantPast

    var body: some View {
        GeometryReader { geo in
            if useAnimationSchedule {
                TimelineView(.animation) { ctx in
                    scene(geoSize: geo.size, now: ctx.date)
                }
            } else {
                TimelineView(.periodic(from: .now, by: 1.0 / 120.0)) { ctx in
                    scene(geoSize: geo.size, now: ctx.date)
                }
            }
        }
        .drawingGroup()
    }

    @ViewBuilder
    private func scene(geoSize: CGSize, now: Date) -> some View {
        ZStack {
            background.ignoresSafeArea()

            Group {
                if let img = image {
                    Color(hue: hue, saturation: 0.9, brightness: 1)
                        .mask(img.resizable().scaledToFit())
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hue: hue, saturation: 0.9, brightness: 1))
                        Text("DVD")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .kerning(2)
                    }
                }
            }
            .frame(width: logoSize.width, height: logoSize.height)
            .shadow(radius: 12)
            .position(pos)
            .scaleEffect(Date() < cornerFlashUntil ? 1.12 : 1.0)
            .animation(.easeOut(duration: 0.18), value: cornerFlashUntil)
        }
        .onChange(of: now) { t in
            tick(now: t, bounds: geoSize)
        }
    }

    private func seed(in size: CGSize) {
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: logoSize.width/2, dy: logoSize.height/2)
        func rand(_ a: CGFloat, _ b: CGFloat) -> CGFloat { CGFloat.random(in: min(a,b)...max(a,b)) }
        pos = CGPoint(x: rand(rect.minX, rect.maxX), y: rand(rect.minY, rect.maxY))

        var v = CGVector(dx: Double.random(in: -1...1), dy: Double.random(in: -1...1))
        if v.dx == 0 && v.dy == 0 { v = .init(dx: 0.7, dy: 0.7) }
        let m = max(0.0001, sqrt(v.dx * v.dx + v.dy * v.dy))
        dir = .init(dx: v.dx / m, dy: v.dy / m)

        lastTick = .now
        seeded = true
    }

    @inline(__always)
    private func nextDistinctHue(from prev: Double, minDelta: Double = 0.08) -> Double {
        let p = prev - floor(prev)
        for _ in 0..<12 {
            let c = Double.random(in: 0...1)
            let d = abs(c - p)
            if min(d, 1 - d) >= minDelta { return c }
        }
        let shifted = p + (Bool.random() ? minDelta : -minDelta)
        return shifted - floor(shifted)
    }

    private func tick(now: Date, bounds: CGSize) {
        guard bounds.width >= logoSize.width, bounds.height >= logoSize.height else { return }
        if !seeded { seed(in: bounds) }

        let dt = max(0, now.timeIntervalSince(lastTick))
        lastTick = now

        var p = pos
        var d = dir

        p.x += d.dx * speed * dt
        p.y += d.dy * speed * dt

        let halfW = logoSize.width / 2
        let halfH = logoSize.height / 2
        var hitX = false
        var hitY = false

        if p.x <= halfW { p.x = halfW; d.dx =  abs(d.dx); hitX = true }
        else if p.x >= bounds.width - halfW { p.x = bounds.width - halfW; d.dx = -abs(d.dx); hitX = true }

        if p.y <= halfH { p.y = halfH; d.dy =  abs(d.dy); hitY = true }
        else if p.y >= bounds.height - halfH { p.y = bounds.height - halfH; d.dy = -abs(d.dy); hitY = true }

        if hitX || hitY { hue = nextDistinctHue(from: hue, minDelta: 0.08) }
        if hitX && hitY { cornerFlashUntil = now.addingTimeInterval(cornerFlashDuration) }

        pos = p
        dir = d
    }
}

// Example
struct DemoBackground: View {
    var body: some View {
        ZStack {
            DVDScreensaverBackground(
                image: Image("dvd.logo"),
                logoSize: .init(width: 110, height: 80),
                speed: 180,
                background: .black
            )
            VStack {
                Spacer()
                Text("Your content here")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview { DemoBackground() }

