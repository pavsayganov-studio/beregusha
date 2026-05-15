import Cocoa

class ViewController: NSViewController {
    
    var connectButton: NSButton!
    var statusLabel: NSTextField!
    var currentPID: String?
    
    override func loadView() {
        // 1. Идеальное матовое стекло
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 260, height: 320))
        visualEffectView.material = .dark
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        
        // 2. Статус (Минималистичный текст)
        statusLabel = NSTextField(frame: NSRect(x: 0, y: 240, width: 260, height: 30))
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.drawsBackground = false
        statusLabel.alignment = .center
        statusLabel.textColor = NSColor(white: 1.0, alpha: 0.7)
        statusLabel.font = NSFont.systemFont(ofSize: 16, weight: .light)
        statusLabel.stringValue = "Ready"
        
        // 3. Воздушная кнопка-кольцо
        connectButton = NSButton(frame: NSRect(x: 70, y: 70, width: 120, height: 120))
        connectButton.title = "OFF"
        connectButton.font = NSFont.systemFont(ofSize: 24, weight: .medium)
        connectButton.isBordered = false
        connectButton.wantsLayer = true
        connectButton.layer?.cornerRadius = 60 // Идеальный круг
        connectButton.layer?.borderWidth = 1.5
        connectButton.layer?.borderColor = NSColor(white: 1.0, alpha: 0.3).cgColor
        connectButton.layer?.backgroundColor = NSColor.clear.cgColor
        connectButton.target = self
        connectButton.action = #selector(toggleConnection)
        
        visualEffectView.addSubview(statusLabel)
        visualEffectView.addSubview(connectButton)
        
        self.view = visualEffectView
    }
    
    @objc func toggleConnection() {
        currentPID != nil ? stopVPN() : startVPN()
    }
    
    func startVPN() {
        statusLabel.stringValue = "Connecting..."
        
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("VPNClient")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true, attributes: nil)
        
        let configPath = appSupport.appendingPathComponent("config.json").path
        let logPath = appSupport.appendingPathComponent("vpn.log").path
        let binaryPath = Bundle.main.path(forResource: "sing-box", ofType: nil)!
        
        let configJSON = """
        {
            "log": { "level": "info" },
            "inbounds": [{ "type": "tun", "tag": "tun-in", "interface_name": "utun9", "inet4_address": "172.19.0.1/30", "auto_route": true, "strict_route": true }],
            "outbounds": [{ "type": "direct", "tag": "direct" }]
        }
        """
        try? configJSON.write(toFile: configPath, atomically: true, encoding: .utf8)
        
        // Надежное экранирование путей для AppleScript
        let shellCommand = "nohup '\(binaryPath)' run -c '\(configPath)' > '\(logPath)' 2>&1 & echo $!"
        let scriptSource = "do shell script \"\(shellCommand)\" with administrator privileges"
        
        var errorInfo: NSDictionary?
        if let output = NSAppleScript(source: scriptSource)?.executeAndReturnError(&errorInfo),
           let pid = output.stringValue, !pid.isEmpty {
            currentPID = pid
            updateUI(connected: true)
        } else {
            statusLabel.stringValue = "Access Denied"
            statusLabel.textColor = .red
        }
    }
    
    func stopVPN() {
        guard let pid = currentPID else { return }
        let scriptSource = "do shell script \"kill -9 \(pid)\" with administrator privileges"
        NSAppleScript(source: scriptSource)?.executeAndReturnError(nil)
        currentPID = nil
        updateUI(connected: false)
    }
    
    func updateUI(connected: Bool) {
        if connected {
            statusLabel.stringValue = "Connected"
            statusLabel.textColor = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
            connectButton.title = "ON"
            connectButton.layer?.borderColor = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.4, alpha: 1.0).cgColor
            connectButton.layer?.backgroundColor = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.4, alpha: 0.1).cgColor
        } else {
            statusLabel.stringValue = "Ready"
            statusLabel.textColor = NSColor(white: 1.0, alpha: 0.7)
            connectButton.title = "OFF"
            connectButton.layer?.borderColor = NSColor(white: 1.0, alpha: 0.3).cgColor
            connectButton.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}
