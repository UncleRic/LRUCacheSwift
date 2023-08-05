//
//  RicCache.swift
//  LRUCacheSwift
//
//  Created by Frederick C. Lee on 8/5/23.
//

import Foundation
import UIKit

class RicCache {
    static var kCacheMemoryLimit = 0

    var cacheDirectory: String
    var appVersion: String
    var memoryCache: [String: Data]
    var recentlyAccessedKeys: [String]

    init(name: String) {
        cacheDirectory = ""
        appVersion = ""
        memoryCache = [String: Data]()
        recentlyAccessedKeys = [String]()
        cacheDirectoryForName(name: name)
    }

    private func cacheDirectoryForName(name: String) {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        cacheDirectory = (paths.first! as NSString).appendingPathComponent(name)

        if !FileManager.default.fileExists(atPath: cacheDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating cache directory: \(error)")
            }
        }

        // Invalidating the Cache.
        // Check if app's current version is dated; if true, then clear it via 'clearCache':

        let lastSavedCacheVersion = UserDefaults.standard.double(forKey: "CACHE_VERSION")
        let currentAppVersion = Double(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0

        if lastSavedCacheVersion < currentAppVersion {
            // assigning current version to preference
            clearCache()

            UserDefaults.standard.set(currentAppVersion, forKey: "CACHE_VERSION")
            UserDefaults.standard.synchronize()
        }

        memoryCache = [String: Data]()
        recentlyAccessedKeys = [String]()

        // you can set this based on the running device and expected cache size
        RicCache.kCacheMemoryLimit = 10

        NotificationCenter.default.addObserver(self, selector: #selector(saveMemoryCacheToDisk(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveMemoryCacheToDisk(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveMemoryCacheToDisk(_:)), name: UIApplication.willTerminateNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }

    @objc private func saveMemoryCacheToDisk(_: Notification) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        for (filename, cacheData) in memoryCache {
            let archivePath = (cacheDirectory as NSString).appendingPathComponent(filename)
            do {
                try cacheData.write(to: URL(fileURLWithPath: archivePath))
            } catch {
                print("Error writing cache data to disk: \(error)")
            }
        }

        memoryCache.removeAll()
    }

     func clearCache() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        do {
            let cachedItems = try FileManager.default.contentsOfDirectory(atPath: cacheDirectory)

            for path in cachedItems {
                let fullPath = (cacheDirectory as NSString).appendingPathComponent(path)
                do {
                    try FileManager.default.removeItem(atPath: fullPath)
                } catch {
                    print("Error removing item at path \(fullPath): \(error)")
                }
            }

            memoryCache.removeAll()
        } catch {
            print("Error getting contents of cache directory: \(error)")
        }
    }

    func cacheData(_ data: Data, toFile fileName: String) {
        memoryCache[fileName] = data
        recentlyAccessedKeys.removeAll { $0 == fileName }
        recentlyAccessedKeys.insert(fileName, at: 0)

        // Write oldest data to file if cache is full:
        if recentlyAccessedKeys.count > RicCache.kCacheMemoryLimit {
            let leastRecentlyUsedDataFilename = recentlyAccessedKeys.removeLast()
            if let leastRecentlyUsedCacheData = memoryCache[leastRecentlyUsedDataFilename] {
                let archivePath = (cacheDirectory as NSString).appendingPathComponent(fileName)
                do {
                    try leastRecentlyUsedCacheData.write(to: URL(fileURLWithPath: archivePath))
                } catch {
                    print("Error writing least recently used cache data to disk: \(error)")
                }

                memoryCache.removeValue(forKey: leastRecentlyUsedDataFilename)
            }
        }
    }

    func cachedArrayItems(_ arrayItems: [Any]) {
        do {
            let archivedData = try NSKeyedArchiver.archivedData(withRootObject: arrayItems, requiringSecureCoding: true)
            cacheData(archivedData, toFile: "RicItems.archive")
        } catch {
            print("Error archiving array items: \(error)")
        }
    }

    func getCachedArrayItems() -> [Any] {
        // 1) Get data from either cache or file.
        // 2) Reposition data in cache.
        // 3) Unarchive (deSerialize) it.

        guard let cachedData = dataForFile(fileName: "RicItems.archive") else {
            return [Any]() // Create an empty array to prevent crashes.
        }

        do {
            let cachedArrayItems = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(cachedData)
            if let arrayItems = cachedArrayItems as? [Any] {
                return arrayItems
            } else {
                print("Error: Unable to convert cached data to an array.")
            }
        } catch {
            print("Error unarchiving cached data: \(error)")
        }

        return [Any]()
    }

    func dataForFile(fileName: String) -> Data? {
        var data: Data?

        data = memoryCache[fileName]
        if data != nil {
            return data // data is present in memory cache
        }

        let archivePath = (cacheDirectory as NSString).appendingPathComponent(fileName)
        data = FileManager.default.contents(atPath: archivePath)

        if let fart = data {
            cacheData(fart, toFile: fileName) // put the recently accessed data to memory cache
        }

        return data
    }
}
