import Cocoa

class ViewController: NSViewController {
    var connectButton: NSButton!
    var statusLabel: NSTextField!
    var currentPID: String?
    
    override func loadView() {
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 250, height: 180))
        visualEffectView.material = .dark
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        
        connectButton = NSButton(frame: NSRect(x: 50, y: 70, width: 150, height: 40))
        connectButton.title = "Connect"
        connectButton.bezelStyle = .regularSquare
        connectButton.target = self
        connectButton.action = #selector(toggleConnection)
        
        statusLabel = NSTextField(frame: NSRect(x: 0, y: 20, width: 250, height: 30))
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.drawsBackground = false
        statusLabel.alignment = .center
        statusLabel.textColor = NSColor.white
        statusLabel.stringValue = "Disconnected"
        statusLabel.font = NSFont.systemFont(ofSize: 14)
        
        visualEffectView.addSubview(connectButton)
        visualEffectView.addSubview(statusLabel)
        
        self.view = visualEffectView
    }
    
    @objc func toggleConnection() {
        if currentPID != nil { stopVPN() } else { startVPN() }
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
            "inbounds": [{
                "type": "tun",
                "tag": "tun-in",
                "interface_name": "utun9",
                "inet4_address": "172.19.0.1/30",
                "auto_route": true,
                "strict_route": true
            }],
            "outbounds": [{ "type": "direct", "tag": "direct" }]
        }
        """
        try? configJSON.write(toFile: configPath, atomically: true, encoding: .utf8)
        
        let shellCommand = "nohup \\\"\(binaryPath)\\\" run -c \\\"\(configPath)\\\" > \\\"\(logPath)\\\" 2>&1 & echo $!"
        let scriptSource = "do shell script \"\(shellCommand)\" with administrator privileges"
        
        var errorInfo: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            let output = scriptObject.executeAndReturnError(&errorInfo)
            if let pid = output.stringValue, !pid.isEmpty {
                self.currentPID = pid
                self.statusLabel.stringValue = "Connected (PID: \(pid))"
                self.connectButton.title = "Disconnect"
                self.connectButton.state = .on
            } else {
                self.statusLabel.stringValue = "Error: Auth Failed"
            }
        }
    }
    
    func stopVPN() {
        guard let pid = currentPID else { return }
        let scriptSource = "do shell script \"kill -9 \(pid)\" with administrator privileges"
        var errorInfo: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            scriptObject.executeAndReturnError(&errorInfo)
            self.currentPID = nil
            self.statusLabel.stringValue = "Disconnected"
            self.connectButton.title = "Connect"
            self.connectButton.state = .off
        }
    }
}
