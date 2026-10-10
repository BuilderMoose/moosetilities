import Foundation
import AppKit

// Get the user's home directory to match the Linux log path
let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
let logDir = "\(homeDir)/scripts/logs"
let formatter = DateFormatter()
formatter.dateFormat = "yyyyMMdd_HHmmss"
let startupTs = formatter.string(from: Date())
let logFile = "\(logDir)/Log_\(startupTs).txt"

// Ensure log directory exists
try? FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true, attributes: nil)

func writeLog(_ message: String, type: String = "INFO") {
    let tsFormatter = DateFormatter()
    tsFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    let ts = tsFormatter.string(from: Date())
    
    let logMessage = "\(ts) [\(type)] - \(message)\n"
    
    // Write to file
    if let data = logMessage.data(using: .utf8) {
        if let fileHandle = FileHandle(forWritingAtPath: logFile) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            try? fileHandle.close()
        } else {
            try? data.write(to: URL(fileURLWithPath: logFile))
        }
    }
    
    // Also print to standard output/error (launchd will capture this)
    if type == "ERROR" {
        fputs(logMessage, stderr)
    } else {
        print(logMessage, terminator: "")
    }
    fflush(stdout)
}

let workspace = NSWorkspace.shared
let notificationCenter = workspace.notificationCenter
let distNotificationCenter = DistributedNotificationCenter.default()

// 1. Detect when the computer is about to sleep
notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil) { _ in
    writeLog("STATUS: ABOUT TO SLEEP")
}

// 2. Detect when the screen is unlocked
distNotificationCenter.addObserver(forName: Notification.Name("com.apple.screenIsUnlocked"), object: nil, queue: nil) { _ in
    writeLog("STATUS: UNLOCKED")
}

// 3. Detect when the screen locks
distNotificationCenter.addObserver(forName: Notification.Name("com.apple.screenIsLocked"), object: nil, queue: nil) { _ in
    writeLog("STATUS: LOCKED")
}

writeLog("SESSION START")

// Keep the script running in the background listening for events
RunLoop.main.run()
