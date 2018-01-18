//
//  Logger.swift
//  V3
//
//  Created by Anonymous on 2017/12/22.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation

public enum LoggerType: String {
    case Error = "LOG_ERROR"
    case Debug = "LOG_DEBUG"
    case Show = "Log_SHOW"
}

let LoggerValueChangeKey: Notification.Name = Notification.Name("LoggerValueChangeKey")

public class Logger {
    static let shared = Logger()

    var logArray: [String]? {
        didSet {
            if let array = logArray, let old = oldValue,  array.count > old.count {
                NotificationCenter.default.post(name: LoggerValueChangeKey, object: nil)
            }
        }
    }
    func log(message: String, lavel: LoggerType = LoggerType.Show) {
        if nil == self.logArray {
            self.logArray = [String]()
        }
        let logMessage = lavel.rawValue + ": " + message
        logArray!.insert(logMessage, at: 0)
        print(logMessage)
    }

    func cleanUp() {
        logArray?.removeAll()
        logArray = nil
    }
}


public class V3FileManager {
    static let shared = V3FileManager()
    private init() { }
    private let fileHandler  = FileHandle()

    private let fileManager = FileManager.default

    func write(_ handler: FileHandle = V3FileManager.shared.fileHandler, data: Data) {
        handler.write(data)
    }

    func readFileWith(filePath: String) -> Data? {
        guard self.fileExist(filePath: filePath) else { return nil }
        let url = URL(fileURLWithPath: filePath)
        var data: Data
        do {
            data = try Data(contentsOf: url, options: .uncached)
        } catch {
            return nil
        }
        return data
    }

    func writeFileWith(filePath: String, data: Data) -> Bool {
        if !self.fileExist(filePath: filePath) {
            if !self.createDir(dir: filePath) {
                return false
            }
        }
        let url = URL(fileURLWithPath: filePath)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return false
        }
        return true
    }

    func getLogFilePath() -> String {
        var cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        if !cacheDir.hasSuffix("/") {
            cacheDir += "/"
        }
        return cacheDir
    }

    func fileExist(filePath: String) -> Bool {
        if self.fileManager.fileExists(atPath: filePath) {
            return true
        } else {
            return false
        }
    }

    func createDir(dir: String) -> Bool {
        let logFilePath = self.getLogFilePath()
        if self.fileManager.fileExists(atPath: logFilePath) {
            return true
        }
        let url = URL(fileURLWithPath: logFilePath, isDirectory: true)
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return false
        }
        return true
    }
}
