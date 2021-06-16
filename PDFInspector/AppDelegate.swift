//
//  AppDelegate.swift
//  PDFInspector
//
//  Created by Jason Harwig on 6/14/21.
//

import Foundation
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
            print("HERE")
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        
        //NSDocumentController.shared.openDocument(nil)
      
        
        for url in urls {
            let str = url.absoluteString.replacingOccurrences(of: "pdfinspect://", with: "")
            if let pdfFile = str.removingPercentEncoding {
                do {
                    let temp = try TemporaryFile(creatingTempDirectoryForFilename: "pdfinspect.pdf")
                    do {
                        try pdfFile.write(to: temp.fileURL, atomically: true, encoding: String.Encoding.utf8)
                        print(temp.fileURL)
                                   
                        NSDocumentController.shared.openDocument(withContentsOf: temp.fileURL, display: true) { (doc, display, error) in
                            if let doc = doc { print(doc) }
                            print(display)
                            if let error = error { print(error) }
                        }
                        
                    } catch let error as NSError {
                        print("Failed writing to URL: \(temp.fileURL), Error: " + error.localizedDescription)
                    }
                } catch let error as NSError {
                    print("Failed generating temp file \(error)")
                }
            }
            
//            print(str.strin                .stringByRemovingPercentEncoding())
        }
        
//        let file = URL(fileURLWithPath: "/Users/jharwig/Downloads/line.pdf")
//        print(file)
//
//        NSDocumentController.shared.openDocument(withContentsOf: file, display: true) { (doc, display, error) in
//            if let doc = doc { print(doc) }
//            print(display)
//            if let error = error { print(error) }
//        }
    }
}


/// A wrapper around a temporary file in a temporary directory. The directory
/// has been especially created for the file, so it's safe to delete when you're
/// done working with the file.
///
/// Call `deleteDirectory` when you no longer need the file.
struct TemporaryFile {
    let directoryURL: URL
    let fileURL: URL
    /// Deletes the temporary directory and all files in it.
    let deleteDirectory: () throws -> Void

    /// Creates a temporary directory with a unique name and initializes the
    /// receiver with a `fileURL` representing a file named `filename` in that
    /// directory.
    ///
    /// - Note: This doesn't create the file!
    init(creatingTempDirectoryForFilename filename: String) throws {
        let (directory, deleteDirectory) = try FileManager.default
            .urlForUniqueTemporaryDirectory()
        self.directoryURL = directory
        self.fileURL = directory.appendingPathComponent(filename)
        self.deleteDirectory = deleteDirectory
    }
}

extension FileManager {
    /// Creates a temporary directory with a unique name and returns its URL.
    ///
    /// - Returns: A tuple of the directory's URL and a delete function.
    ///   Call the function to delete the directory after you're done with it.
    ///
    /// - Note: You should not rely on the existence of the temporary directory
    ///   after the app is exited.
    func urlForUniqueTemporaryDirectory(preferredName: String? = nil) throws
        -> (url: URL, deleteDirectory: () throws -> Void)
    {
        let basename = preferredName ?? UUID().uuidString

        var counter = 0
        var createdSubdirectory: URL? = nil
        repeat {
            do {
                let subdirName = counter == 0 ? basename : "\(basename)-\(counter)"
                let subdirectory = temporaryDirectory
                    .appendingPathComponent(subdirName, isDirectory: true)
                try createDirectory(at: subdirectory, withIntermediateDirectories: false)
                createdSubdirectory = subdirectory
            } catch CocoaError.fileWriteFileExists {
                // Catch file exists error and try again with another name.
                // Other errors propagate to the caller.
                counter += 1
            }
        } while createdSubdirectory == nil

        let directory = createdSubdirectory!
        let deleteDirectory: () throws -> Void = {
            try self.removeItem(at: directory)
        }
        return (directory, deleteDirectory)
    }
}
