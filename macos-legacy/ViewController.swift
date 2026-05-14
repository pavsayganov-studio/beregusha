import Cocoa

class ViewController: NSViewController {
    
    var connectButton: NSButton!
    var statusLabel: NSTextField!
    var titleLabel: NSTextField!
    var currentPID: String?
    
    override func loadView() {
        // 1. Создаем эффект матового стекла (Yosemite 10.10 API)
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 280, height: 350))
        visualEffectView.material = .dark
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        
        // 2. Заголовок "Hiddify"
        titleLabel = NSTextField(frame: NSRect(x: 0, y: 280, width: 280, height: 40))
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.drawsBackground = false
        titleLabel.alignment = .center
        titleLabel.textColor = NSColor.white
        // Используем HelveticaNeue-Light для "воздушного" дизайна 10.10
        titleLabel.font = NSFont(name: "HelveticaNeue-Light", size: 28) ?? NSFont.systemFont(ofSize: 28)
        titleLabel.stringValue = "Hiddify"
        
        // 3. Статус (Подключен / Отключен)
        statusLabel = NSTextField(frame: NSRect(x: 0, y: 240, width: 280, height: 20))
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.drawsBackground = false
        statusLabel.alignment = .center
        statusLabel.textColor = NSColor(calibratedWhite: 1.0, alpha: 0.6)
        statusLabel.font = NSFont(name: "HelveticaNeue", size: 14) ?? NSFont.systemFont(ofSize: 14)
        statusLabel.stringValue = "Ready to connect"
        
        // 4. Большая минималистичная круглая кнопка
        connectButton = NSButton(frame: NSRect(x: 65, y: 60, width: 150, height: 150))
        connectButton.title = "OFF"
        connectButton.font = NSFont(name: "HelveticaNeue-Medium", size: 32)
        connectButton.isBordered = false
        connectButton.wantsLayer = true
        connectButton.layer?.backgroundColor = NSColor(calibratedWhite: 1.0, alpha: 0.1).cgColor
        connectButton.layer?.cornerRadius = 75 // Делает кнопку круглой (150/2)
        connectButton.layer?.borderWidth = 2
        connectButton.layer?.borderColor = NSColor(calibratedWhite: 1.0, alpha: 0.3).cgColor
        connectButton.target = self
        connectButton.action = #selector(toggleConnection)
        
        visualEffectView.addSubview(titleLabel)
        visualEffectView.addSubview(statusLabel)
        visualEffectView.addSubview(connectButton)
        
        self.view = visualEffectView
    }
    
    @objc func toggleConnection() {
        if currentPID != nil {
            stopVPN()
        } else {
            startVPN()
        }
    }
    
    func startVPN() {
        statusLabel.stringValue = "Connecting..."
        statusLabel.textColor = NSColor.orange
        
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("VPNClient")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true, attributes: nil)
        
        let configPath = appSupport.appendingPathComponent("config.json").path
        let logPath = appSupport.appendingPathComponent("vpn.log").path
        let binaryPath = Bundle.main.path(forResource: "sing-box", ofType: nil)!
        
        // Заглушка конфигурации (позже мы научим код читать реальный конфиг Hiddify)
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
        
        // Запуск sing-box через AppleScript с запросом прав
        let shellCommand = "nohup \\\"\(binaryPath)\\\" run -c \\\"\(configPath)\\\" > \\\"\(logPath)\\\" 2>&1 & echo $!"
        let scriptSource = "do shell script \"\(shellCommand)\" with administrator privileges"
        
        var errorInfo: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            let output = scriptObject.executeAndReturnError(&errorInfo)
            if let pid = output.stringValue, !pid.isEmpty {
                self.currentPID = pid
                self.statusLabel.stringValue = "Secured"
                self.statusLabel.textColor = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
                
                // Анимация кнопки
                self.connectButton.title = "ON"
                self.connectButton.layer?.backgroundColor = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.4, alpha: 0.2).cgColor
                self.connectButton.layer?.borderColor = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.4, alpha: 1.0).cgColor
            } else {
                self.statusLabel.stringValue = "Auth Failed"
                self.statusLabel.textColor = NSColor.red
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
            self.statusLabel.stringValue = "Ready to connect"
            self.statusLabel.textColor = NSColor(calibratedWhite: 1.0, alpha: 0.6)
            
            // Возвращаем кнопку в исходное состояние
            self.connectButton.title = "OFF"
            self.connectButton.layer?.backgroundColor = NSColor(calibratedWhite: 1.0, alpha: 0.1).cgColor
            self.connectButton.layer?.borderColor = NSColor(calibratedWhite: 1.0, alpha: 0.3).cgColor
        }
    }
}
