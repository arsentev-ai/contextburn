// contextburn — расход токенов: полоска в строке меню + разворачиваемая панель
// с интерактивным почасовым графиком. Сутки считаются от 6:00 (CONTEXTBURN_DAY_START).
import Cocoa

// CONTEXTBURN_<key>, falling back to the former TOKMON_<key> so existing setups keep working.
func envVar(_ key: String) -> String? {
    let e = ProcessInfo.processInfo.environment
    if let v = e["CONTEXTBURN_" + key], !v.isEmpty { return v }
    return e["TOKMON_" + key]
}

// Interface language: English by default. Russian via CONTEXTBURN_LANG=ru, or a file
// ~/.config/contextburn/lang containing "ru". The app is normally launched from Finder, where
// environment variables never reach it, so the file is the switch that actually works.
let UI_LANG: String = {
    if let v = envVar("LANG"), !v.isEmpty {
        return String(v.lowercased().prefix(2))
    }
    let path = NSString(string: "~/.config/contextburn/lang").expandingTildeInPath
    if let raw = try? String(contentsOfFile: path, encoding: .utf8) {
        return String(raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().prefix(2))
    }
    return "en"
}()

func tr(_ en: String, _ ru: String) -> String { UI_LANG == "ru" ? ru : en }


// Путь к CLI. Переопределяется переменной CONTEXTBURN_BIN, иначе ищем в обычных местах.
let CLI = envVar("BIN")
    ?? ["\(NSHomeDirectory())/bin/contextburn", "/usr/local/bin/contextburn", "/opt/homebrew/bin/contextburn"]
        .first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    ?? "contextburn"
let REFRESH: TimeInterval = 60
let W_FULL: CGFloat = 470

func fmt(_ n: Double) -> String {
    if n >= 1e9 { return String(format: "%.1fkkk", n/1e9) }
    if n >= 1e6 { return String(format: "%.0fkk", n/1e6) }
    if n >= 1e3 { return String(format: "%.0fk", n/1e3) }
    return String(format: "%.0f", n)
}
func pad(_ s: String, _ n: Int) -> String {
    let t = s.count > n ? String(s.prefix(n)) : s
    return t + String(repeating: " ", count: max(0, n - t.count))
}
func lpad(_ s: String, _ n: Int) -> String { String(repeating: " ", count: max(0, n - s.count)) + s }

// ── текст панели
final class Text {
    let s = NSMutableAttributedString()
    func add(_ t: String, size: CGFloat = 11.5, color: NSColor = .white,
             mono: Bool = true, weight: NSFont.Weight = .regular, after: CGFloat = 2) {
        let p = NSMutableParagraphStyle(); p.paragraphSpacing = after; p.lineSpacing = 1
        let f = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
                     : NSFont.systemFont(ofSize: size, weight: weight)
        s.append(NSAttributedString(string: t + "\n",
                 attributes: [.font: f, .foregroundColor: color, .paragraphStyle: p]))
    }
    func section(_ t: String) {
        add(t.uppercased(), size: 9.5, color: NSColor(white: 1, alpha: 0.4),
            mono: false, weight: .semibold, after: 3)
    }
    var height: CGFloat {
        ceil(s.boundingRect(with: NSSize(width: W_FULL - 26, height: 4000),
                            options: [.usesLineFragmentOrigin, .usesFontLeading]).height)
    }
}

// ── график: столбцы по часам, подсказка под курсором
final class ChartView: NSView {
    var values: [Double] = []
    var labels: [String] = []
    var caption = ""
    var hover: Int?
    var selected: Int?
    var onSelect: ((Int?) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil))
    }
    override func mouseMoved(with e: NSEvent) {
        let p = convert(e.locationInWindow, from: nil)
        let n = max(values.count, 1)
        let idx = min(max(Int(p.x / (bounds.width / CGFloat(n))), 0), n - 1)
        if idx != hover { hover = idx; needsDisplay = true }
    }
    override func mouseExited(with e: NSEvent) { hover = nil; needsDisplay = true }
    override func mouseDown(with e: NSEvent) { }            // клик по графику не сворачивает панель
    override func mouseDragged(with e: NSEvent) { }         // и не двигает окно (иначе оно прыгало)
    override func mouseUp(with e: NSEvent) {
        let p = convert(e.locationInWindow, from: nil)
        let n = max(values.count, 1)
        let idx = min(max(Int(p.x / (bounds.width / CGFloat(n))), 0), n - 1)
        selected = (selected == idx) ? nil : idx
        needsDisplay = true
        onSelect?(selected)
    }

    override func draw(_ r: NSRect) {
        let n = max(values.count, 1)
        let topPad: CGFloat = 17, botPad: CGFloat = 13
        let hh = max(6, bounds.height - topPad - botPad)
        let mx = max(values.max() ?? 1, 1)
        let slot = bounds.width / CGFloat(n)
        let blue = NSColor(red: 0.42, green: 0.76, blue: 1, alpha: 1)

        for (i, v) in values.enumerated() {
            let bh = max(1.5, CGFloat(v / mx) * hh)
            let rect = NSRect(x: CGFloat(i) * slot + 1.5, y: botPad,
                              width: max(2.5, slot - 3), height: bh)
            let isSel = (i == selected)
            let col: NSColor = isSel ? NSColor(red: 1, green: 0.82, blue: 0.35, alpha: 1)
                                     : (i == hover ? .white : blue.withAlphaComponent(0.8))
            col.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()
            if isSel {                                   // подсветка выбранного часа
                NSColor(red: 1, green: 0.82, blue: 0.35, alpha: 0.16).setFill()
                NSBezierPath(rect: NSRect(x: CGFloat(i) * slot, y: botPad - 2,
                                          width: slot, height: hh + 4)).fill()
                NSColor(red: 1, green: 0.82, blue: 0.35, alpha: 1).setFill()
                NSBezierPath(rect: NSRect(x: CGFloat(i) * slot + 1.5, y: botPad - 3,
                                          width: max(2.5, slot - 3), height: 2)).fill()
            }
        }
        // часы под столбцами
        let la: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: NSColor(white: 1, alpha: 0.38)]
        let step = max(1, Int(ceil(Double(n) / 8.0)))
        for (i, l) in labels.enumerated() where i % step == 0 || i == n - 1 {
            (l as NSString).draw(at: NSPoint(x: CGFloat(i) * slot, y: 0), withAttributes: la)
        }
        // подсказка
        let ta: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10.5, weight: .semibold),
            .foregroundColor: hover == nil ? NSColor(white: 1, alpha: 0.4) : NSColor.white]
        let txt: String
        if let h = hover, h < values.count {
            txt = "\(labels[h]):00–\(labels[h]):59   \(fmt(values[h]))"
        } else { txt = caption }
        (txt as NSString).draw(at: NSPoint(x: 0, y: bounds.height - topPad + 3), withAttributes: ta)
    }
}

final class HudView: NSView {
    var onDrag: ((NSPoint) -> Void)?
    var onClick: ((NSPoint) -> Void)?
    private var start = NSPoint.zero
    private var moved = false
    private var dragging = false
    override func mouseDown(with e: NSEvent) { start = e.locationInWindow; moved = false; dragging = true }
    override func mouseDragged(with e: NSEvent) {
        guard dragging, let w = window else { return }
        if abs(e.locationInWindow.x - start.x) < 3 && abs(e.locationInWindow.y - start.y) < 3 { return }
        moved = true
        let p = NSEvent.mouseLocation
        let o = NSPoint(x: p.x - start.x, y: p.y - start.y)
        w.setFrameOrigin(o); onDrag?(o)
    }
    override func mouseUp(with e: NSEvent) {
        if !moved && dragging { onClick?(convert(e.locationInWindow, from: nil)) }
        dragging = false
    }
}

/// Полоска в строке меню — видна всегда, клик открывает/закрывает панель.
final class Bar {
    let panel: NSPanel
    let view = HudView()
    let back = NSView()
    let label = NSTextField(labelWithString: "⚡…")

    init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 150, height: 22),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.appearance = NSAppearance(named: .darkAqua)
        view.frame = NSRect(x: 0, y: 0, width: 150, height: 22)
        back.frame = view.bounds
        back.autoresizingMask = [.width, .height]
        back.wantsLayer = true
        back.layer?.backgroundColor = NSColor(calibratedWhite: 0.09, alpha: 0.96).cgColor
        back.layer?.cornerRadius = 7
        back.layer?.borderWidth = 1
        back.layer?.borderColor = NSColor(white: 1, alpha: 0.14).cgColor
        view.addSubview(back)
        label.frame = NSRect(x: 9, y: 3, width: 132, height: 16)
        label.autoresizingMask = [.width]
        view.addSubview(label)
        panel.contentView = view
        let d = UserDefaults.standard
        view.onDrag = { p in d.set(Double(p.x), forKey: "barX"); d.set(Double(p.y), forKey: "barY") }
        panel.orderFrontRegardless()
    }

    func set(_ text: String, color: NSColor) {
        label.attributedStringValue = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 12.5, weight: .semibold), .foregroundColor: color])
        let w = ceil(label.attributedStringValue.size().width) + 26
        var f = panel.frame
        f.size = NSSize(width: w, height: 22)
        let d = UserDefaults.standard
        if d.double(forKey: "barX") > 10 { f.origin.x = d.double(forKey: "barX") }
        else if let s = NSScreen.main { f.origin.x = s.frame.maxX - w - 14 }
        if d.double(forKey: "barY") > 10 { f.origin.y = d.double(forKey: "barY") }
        else if let s = NSScreen.main { f.origin.y = s.visibleFrame.maxY - 26 }
        panel.setFrame(f, display: true)
        label.frame = NSRect(x: 9, y: 3, width: w - 18, height: 16)
    }
    func corner() {
        guard let s = NSScreen.main else { return }
        let o = NSPoint(x: s.frame.maxX - panel.frame.width - 14, y: s.visibleFrame.maxY - 26)
        panel.setFrameOrigin(o)
        UserDefaults.standard.set(Double(o.x), forKey: "barX")
        UserDefaults.standard.set(Double(o.y), forKey: "barY")
    }
    func show(_ v: Bool) { v ? panel.orderFrontRegardless() : panel.orderOut(nil) }
}

final class HUD {
    var compactMode = false
    let panel: NSPanel
    let view = HudView()
    let back = NSView()
    let header = NSTextField(labelWithString: "")
    let body = NSTextField(labelWithString: "")
    let chart = ChartView()
    let chev = NSTextField(labelWithString: "▴")

    init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 160, height: 22),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.acceptsMouseMovedEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.appearance = NSAppearance(named: .darkAqua)

        view.frame = NSRect(x: 0, y: 0, width: 160, height: 22)
        back.frame = view.bounds
        back.autoresizingMask = [.width, .height]
        back.wantsLayer = true
        view.addSubview(back)
        for f in [header, body] {
            f.maximumNumberOfLines = 30
            f.lineBreakMode = .byClipping
            f.textColor = .white
            view.addSubview(f)
        }
        view.addSubview(chart)
        chev.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        chev.textColor = NSColor(white: 1, alpha: 0.5)
        chev.alignment = .center
        view.addSubview(chev)
        panel.contentView = view

        let d = UserDefaults.standard
        view.onDrag = { [weak self] p in
            let k = (self?.compactMode ?? false) ? ("barX", "barY") : ("hudX", "hudY")
            d.set(Double(p.x), forKey: k.0); d.set(Double(p.y), forKey: k.1)
        }
        panel.orderFrontRegardless()
    }

    func corner() -> NSPoint {
        guard let s = NSScreen.main else { return NSPoint(x: 100, y: 100) }
        return NSPoint(x: s.visibleFrame.maxX - W_FULL - 14, y: s.visibleFrame.maxY - 400)
    }

    /// Свёрнуто — полоска в строке меню; развёрнуто — панель с графиком.
    func render(compact: Bool, header ht: Text, body bt: Text?, values: [Double], labels: [String], caption: String) {
        let d = UserDefaults.standard
        compactMode = compact
        header.attributedStringValue = ht.s
        var f = panel.frame
        let top = f.maxY, right = f.maxX

        if compact {
            back.layer?.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.34).cgColor
            back.layer?.cornerRadius = 6
            back.layer?.borderWidth = 0
            panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
            chart.isHidden = true; body.isHidden = true; chev.isHidden = true
            let w = ceil(ht.s.boundingRect(with: NSSize(width: 2000, height: 80),
                        options: [.usesLineFragmentOrigin, .usesFontLeading]).width) + 24
            let h: CGFloat = 22
            f.size = NSSize(width: w, height: h)
            if d.double(forKey: "barX") > 10 { f.origin.x = d.double(forKey: "barX") }
            else if let s = NSScreen.main { f.origin.x = s.frame.midX - w / 2 }
            if d.double(forKey: "barY") > 10 { f.origin.y = d.double(forKey: "barY") }
            else if let s = NSScreen.main { f.origin.y = s.frame.maxY - h - 6 }
            panel.setFrame(f, display: true)
            header.frame = NSRect(x: 10, y: 3, width: w - 20, height: 16)
            return
        }

        back.layer?.backgroundColor = NSColor(calibratedWhite: 0.09, alpha: 0.985).cgColor
        back.layer?.cornerRadius = 11
        back.layer?.borderWidth = 1
        back.layer?.borderColor = NSColor(white: 1, alpha: 0.13).cgColor
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
        chart.isHidden = false; body.isHidden = false; chev.isHidden = false
        chart.values = values; chart.labels = labels; chart.caption = caption
        chart.needsDisplay = true
        body.attributedStringValue = bt?.s ?? NSAttributedString(string: "")

        let hHead = ht.height, hChart: CGFloat = 66, hBody = bt?.height ?? 0
        let total = 10 + hHead + 4 + hChart + 8 + hBody + 12
        f.size = NSSize(width: W_FULL, height: total)
        if compactWasBefore { f.origin.x = d.double(forKey: "hudX") > 10 ? d.double(forKey: "hudX") : corner().x
                              f.origin.y = (d.double(forKey: "hudY") > 10 ? d.double(forKey: "hudY") : corner().y) }
        else { f.origin.y = top - total; f.origin.x = right - W_FULL }
        panel.setFrame(f, display: true)
        header.frame = NSRect(x: 13, y: total - 10 - hHead, width: W_FULL - 26, height: hHead)
        chart.frame  = NSRect(x: 13, y: total - 10 - hHead - 4 - hChart, width: W_FULL - 26, height: hChart)
        body.frame   = NSRect(x: 13, y: 12, width: W_FULL - 26, height: hBody)
        chev.frame   = NSRect(x: W_FULL - 34, y: total - 27, width: 24, height: 18)
    }
    var compactWasBefore = true
    /// Зона уголка «свернуть» в координатах окна.
    var chevRect: NSRect { NSRect(x: panel.frame.width - 40, y: panel.frame.height - 32, width: 34, height: 28) }
    func show(_ v: Bool) { v ? panel.orderFrontRegardless() : panel.orderOut(nil) }
}

final class Controller: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    var bar: Bar!
    var hud: HUD!
    var hudOn = true, expanded = false, busy = false
    var state: [String: Any] = [:]
    var timer: Timer?
    var warn: Double = 80_000_000, alarm: Double = 160_000_000

    func applicationDidFinishLaunching(_ n: Notification) {
        if let v = envVar("WARN").flatMap(Double.init) { warn = v }
        if let v = envVar("ALARM").flatMap(Double.init) { alarm = v }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.isVisible = true
        item.button?.title = "⚡…"
        item.menu = NSMenu()
        hud = HUD()
        bar = Bar()
        bar.view.onClick = { [weak self] _ in self?.toggleSize() }
        hudOn = UserDefaults.standard.object(forKey: "hudOn") as? Bool ?? true
        expanded = UserDefaults.standard.bool(forKey: "hudExpanded")
        hud.view.onClick = { [weak self] p in                   // панель закрывается только уголком
            guard let me = self else { return }
            if me.hud.chevRect.contains(p) { me.toggleSize() }
        }
        hud.chart.onSelect = { [weak self] _ in self?.render() }
        bar.show(hudOn)
        hud.show(hudOn && expanded)
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: REFRESH, repeats: true) { _ in self.refresh() }
    }

    @objc func refresh() {
        if busy { return }
        busy = true
        DispatchQueue.global(qos: .utility).async {
            let out = self.shell(CLI, ["--json", "26"])
            var p: [String: Any] = [:]
            if let d = out.data(using: .utf8),
               let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any] { p = j }
            DispatchQueue.main.async {
                self.busy = false
                if !p.isEmpty { self.state = p }
                self.render()
            }
        }
    }

    func shell(_ cmd: String, _ args: [String]) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", cmd] + args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/bin:/bin:/usr/local/bin:" + (env["PATH"] ?? "")
        p.environment = env
        let pipe = Pipe(); p.standardOutput = pipe; p.standardError = Pipe()
        do { try p.run() } catch { return "" }
        let d = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return String(data: d, encoding: .utf8) ?? ""
    }

    func render() {
        let w1 = state["w1"] as? Double ?? 0
        let dayTotal = state["day_total"] as? Double ?? 0
        let dayFrom = state["day_start"] as? String ?? "06:00"
        let hot = state["hot_minutes"] as? Double ?? 0
        let hard = w1 > alarm, soft = w1 > warn
        let accent: NSColor = hard ? NSColor(red: 1, green: 0.42, blue: 0.38, alpha: 1)
                                   : (soft ? NSColor(red: 1, green: 0.76, blue: 0.3, alpha: 1) : .white)
        let mark = hard ? "⛔" : (soft ? "⚠" : "⚡")

        item.button?.attributedTitle = NSAttributedString(string: "\(mark)\(fmt(dayTotal))", attributes: [
            .foregroundColor: hard ? NSColor.systemRed : (soft ? NSColor.systemOrange : NSColor.labelColor),
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)])

        // полоска всегда оранжевая; тревогу показывает значок ⚡/⚠/⛔
        bar.set("\(mark) \(fmt(dayTotal))", color: NSColor(red: 1, green: 0.76, blue: 0.3, alpha: 1))
        bar.show(hudOn)
        hud.show(hudOn && expanded)
        if !expanded { buildMenu(w1: w1, day: dayTotal, from: dayFrom); return }

        let head = Text()

        let status = hard ? (hot >= 30 ? tr("burning \(Int(hot)) min straight", "трэш \(Int(hot)) мин подряд") : tr("spike", "всплеск"))
                          : (soft ? tr("elevated", "повышенный") : tr("calm", "спокойно"))
        head.add("\(mark) \(fmt(dayTotal))  " + tr("today since \(dayFrom)", "за сутки с \(dayFrom)"), size: 15, color: accent,
                 mono: false, weight: .bold, after: 1)
        head.add(tr("now \(fmt(w1))/h · \(status)", "сейчас \(fmt(w1))/час · \(status)"), size: 10.5,
                 color: NSColor(white: 1, alpha: 0.5), mono: false, after: 0)

        let t = Text()
        let hoursArr = state["day_hours"] as? [[String: Any]] ?? []
        let labels = state["day_labels"] as? [String] ?? []
        if let sel = hud.chart.selected, sel < hoursArr.count, sel < labels.count {
            let hr = hoursArr[sel]
            let hh = labels[sel]
            let tot = hr["total"] as? Double ?? 0
            t.add(tr("hour \(hh):00–\(hh):59   \(fmt(tot))", "выбран час \(hh):00–\(hh):59   \(fmt(tot))"), size: 12.5,
                  color: NSColor(red: 1, green: 0.82, blue: 0.35, alpha: 1), weight: .bold, after: 6)
            let hs = hr["hosts"] as? [String: Double] ?? [:]
            let mxh = max(hs.values.max() ?? 1, 1)
            t.section(tr("machines this hour", "машины в этот час"))
            if hs.isEmpty { t.add(tr("  quiet", "  тихо"), color: NSColor(white: 1, alpha: 0.4)) }
            for (h, v) in hs.sorted(by: { $0.value > $1.value }) {
                t.add("\(pad(h, 11))\(lpad(fmt(v), 7))  \(String(repeating: "▇", count: max(1, Int((v / mxh) * 14))))",
                      color: .white, after: 1)
            }
            t.s.append(NSAttributedString(string: "\n"))
            t.section(tr("tasks this hour", "задачи в этот час"))
            for x in (hr["top"] as? [[String: Any]] ?? []).prefix(5) {
                let nm = ((x["sub"] as? Bool == true) ? tr("sub-", "суб·") : "") + ((x["task"] as? String) ?? "?")
                t.add("\(pad((x["host"] as? String) ?? "?", 9))\(pad(nm, 23))\(lpad(fmt(x["v"] as? Double ?? 0), 7))",
                      color: NSColor(white: 1, alpha: 0.9), after: 1)
            }
            t.add(tr("click the bar again to show the whole day", "клик по столбцу ещё раз — показать все сутки"), size: 9.5,
                  color: NSColor(white: 1, alpha: 0.35), mono: false, after: 0)
            hud.render(compact: false, header: head, body: t,
                       values: state["day_series"] as? [Double] ?? [],
                       labels: labels, caption: tr("hour \(hh):00 · click the bar to clear", "выбран \(hh):00 · клик по столбцу снимает выбор"))
            hud.compactWasBefore = false
            buildMenu(w1: w1, day: dayTotal, from: dayFrom)
            return
        }
        let sp = state["day_split"] as? [String: Double] ?? [:]
        t.add(tr("new \(fmt(sp["new"] ?? 0))  +  re-read \(fmt(sp["reread"] ?? 0))  (same context again)", "новых \(fmt(sp["new"] ?? 0))  +  перечитано \(fmt(sp["reread"] ?? 0))  (тот же контекст заново)"),
              size: 10, color: NSColor(white: 1, alpha: 0.45), after: 7)

        t.section(tr("machines · today since \(dayFrom)", "машины · сутки с \(dayFrom)"))
        let hd = state["day_hosts"] as? [String: Double] ?? [:]
        let mx = max(hd.values.max() ?? 1, 1)
        var idle: [String] = []
        for (h, v) in hd.sorted(by: { $0.value > $1.value }) {
            if v <= 0 { idle.append(h); continue }
            t.add("\(pad(h, 11))\(lpad(fmt(v), 7))  \(String(repeating: "▇", count: max(1, Int((v / mx) * 14))))",
                  color: .white, after: 1)
        }
        if !idle.isEmpty {
            t.add(tr("quiet: ", "тихо: ") + idle.joined(separator: ", "), size: 10,
                  color: NSColor(white: 1, alpha: 0.32), after: 1)
        }
        t.s.append(NSAttributedString(string: "\n"))

        let accs = state["day_accounts"] as? [String: Double] ?? [:]
        if accs.count > 1 {
            t.section(tr("subscriptions · today", "подписки · сутки"))
            for (a, v) in accs.sorted(by: { $0.value > $1.value }) where v > 0 {
                t.add("\(pad(a, 17))\(lpad(fmt(v), 7))", color: NSColor(white: 1, alpha: 0.88), after: 1)
            }
            t.s.append(NSAttributedString(string: "\n"))
        }

        t.section(tr("top tasks · today", "топ задач · сутки"))
        let top = state["day_top"] as? [[String: Any]] ?? []
        if top.isEmpty { t.add(tr("  empty", "  пусто"), color: NSColor(white: 1, alpha: 0.4)) }
        for x in top.prefix(4) {
            let nm = ((x["sub"] as? Bool == true) ? tr("sub-", "суб·") : "") + ((x["task"] as? String) ?? "?")
            let ctx = x["ctx"] as? Double ?? 0
            let c: NSColor = ctx > 150_000 ? NSColor(red: 1, green: 0.5, blue: 0.45, alpha: 1)
                                           : NSColor(white: 1, alpha: 0.88)
            t.add("\(pad((x["host"] as? String) ?? "?", 9))\(pad(nm, 23))\(lpad(fmt(x["day"] as? Double ?? 0), 7))",
                  color: c, after: 1)
        }

        hud.render(compact: false, header: head, body: t,
                   values: state["day_series"] as? [Double] ?? [],
                   labels: state["day_labels"] as? [String] ?? [],
                   caption: tr("by hour since \(dayFrom) · hover for detail", "по часам с \(dayFrom) · наведи курсор"))
        hud.compactWasBefore = false
        buildMenu(w1: w1, day: dayTotal, from: dayFrom)
    }

    func buildMenu(w1: Double, day: Double, from: String) {
        let m = NSMenu(); m.autoenablesItems = false
        mhead(m, tr("today since \(from): \(fmt(day))   ·   last hour \(fmt(w1))", "сутки с \(from): \(fmt(day))   ·   за час \(fmt(w1))"))
        if let e = state["errors"] as? [String: String], !e.isEmpty {
            for (h, v) in e { mhead(m, "⛔ \(h): \(v)") }
        }
        m.addItem(.separator())
        madd(m, expanded ? tr("Close panel", "Закрыть панель") : tr("Open panel", "Открыть панель"), #selector(toggleSize), "e")
        madd(m, hudOn ? tr("Hide all", "Спрятать всё") : tr("Show", "Показать"), #selector(toggleHUD), "h")
        madd(m, tr("Reset strip and panel position", "Вернуть полоску и панель на место"), #selector(cornerHUD), "c")
        madd(m, tr("Refresh now", "Обновить сейчас"), #selector(refresh), "r")
        madd(m, tr("Detailed breakdown…", "Подробный разбор причин…"), #selector(openReport), "d")
        madd(m, tr("Quit", "Выход"), #selector(quit), "q")
        item.menu = m
    }
    func mhead(_ m: NSMenu, _ s: String) {
        let i = NSMenuItem(title: s, action: nil, keyEquivalent: "")
        i.attributedTitle = NSAttributedString(string: s, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold)])
        i.isEnabled = false; m.addItem(i)
    }
    func madd(_ m: NSMenu, _ s: String, _ sel: Selector, _ k: String) {
        let i = NSMenuItem(title: s, action: sel, keyEquivalent: k); i.target = self; m.addItem(i)
    }

    @objc func toggleSize() {
        expanded.toggle(); UserDefaults.standard.set(expanded, forKey: "hudExpanded"); render()
    }
    @objc func toggleHUD() {
        hudOn.toggle(); UserDefaults.standard.set(hudOn, forKey: "hudOn")
        bar.show(hudOn); hud.show(hudOn && expanded); render()
    }
    @objc func cornerHUD() {
        bar.corner()
        let o = hud.corner()
        hud.panel.setFrameOrigin(o)
        UserDefaults.standard.set(Double(o.x), forKey: "hudX")
        UserDefaults.standard.set(Double(o.y), forKey: "hudY")
    }
    @objc func openReport() {
        DispatchQueue.global(qos: .utility).async {
            let out = self.shell(CLI, ["detail", "24"])
            let path = NSTemporaryDirectory() + "contextburn-detail.txt"
            try? out.write(toFile: path, atomically: true, encoding: .utf8)
            let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            p.arguments = ["-t", path]; try? p.run()
        }
    }
    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let ctrl = Controller()
app.delegate = ctrl
app.setActivationPolicy(.accessory)
app.run()
