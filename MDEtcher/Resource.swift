//
//  Resource.swift
//  MDEtcher
//
//  Created by psksvp on 30/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import AppKit
import CommonSwift


class Resource
{
  static var bundlePath: String
  {
    get
    { // I want it crashes, if it is not there
      return Bundle.main.resourcePath!
    }
  }
  
  static var applicationSupportPath: String
  {
    get
    { // I want it crashes, if it is not there
      return FS.applicationSupportPath(forName: "MDEtcher",
                                       createIfNotExists: true)!
    }
  }
  
  static var pandocExecutable: String
  {
    get
    {// I want it crashes, if it is not there
      return Resource.path(forResourceName: "pandoc", inFolder: "pandoc")!
    }
  }
  
  static var mathJax: String
  {
    get
    {// I want it crashes, if it is not there
      return Resource.path(forResourceName: "MathJax.js", inFolder: "MathJax")!
    }
  }
  
  static var busyAnimation: NSImage
  {
    get
    { // I want it crashes, if it is not there
      return NSImage(contentsOfFile: "\(Resource.bundlePath)/images/busy.gif")!
    }
  }
  
  class func path(forResourceName name: String, inFolder folder: String) -> String?
  {
    let subFolderName = folder.isEmpty ? "" : "/\(folder)"
    let p1 = "\(Resource.bundlePath)\(subFolderName)/\(name)"
    let p2 = "\(Resource.applicationSupportPath)\(subFolderName)/\(name)"
    
    if FileManager.default.fileExists(atPath: p1)
    {
      return p1
    }
    else if FileManager.default.fileExists(atPath: p2)
    {
      return p2
    }
    else
    {
      return nil
    }
  }
  
  class func css(_ name: String) -> String?
  {
    return Resource.path(forResourceName: name, inFolder: "css")
  }
  
  class func image(_ name: String) -> String?
  {
    return Resource.path(forResourceName: name, inFolder: "images")
  }
  
  class func contents(ofResourceFolder folder: String) -> [String]?
  {
    let c1 = FS.contentsOfDirectory("\(Resource.bundlePath)/\(folder)")
    let c2 = FS.contentsOfDirectory("\(Resource.applicationSupportPath)/\(folder)")
    
    switch (c1, c2)
    {
      case (.some(let a), .some(let b)) : return (a + b).filter { $0.first != "."}
      case (.none, .some(let b))        : return b.filter { $0.first != "."}
      case (.some(let a), .none)        : return a.filter { $0.first != "."}
      default                           : return nil
    }
  }
  
  static var xelatexPath: String?
  {
    get
    {
      func askUserToSelect()
      {
        let fs = FileSelectorController.shared
        fs.messageText = "Export to pdf require XeLatex.\nPlease enter path to Xelatex"
        if .OK == fs.showModal()
        {
          UserDefaults.standard.set(fs.filePath, forKey: "xelatexPath")
        }
      }
      
      var count = 1
      while count >= 0
      {
        switch UserDefaults.standard.value(forKey: "xelatexPath")
        {
          case .some(let path as String) : return path
          default                        : askUserToSelect()
                                           count = count - 1
        }
      }
      return nil
    }
  }
  
  
  
}
