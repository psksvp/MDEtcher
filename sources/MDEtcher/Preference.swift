//
//  Preference.swift
//  MDEtcher
//
//  Created by psksvp on 22/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import AppKit
import CommonSwift


struct Preference
{
  static func reset()
  {
    Preference.scrollPreview = true
    Preference.proofReadVoiceName = "Samantha"
    Preference.proofReadVoiceRate = Float(160)
    Preference.editorOnLeft = true
  }
  
  static var scrollPreview: Bool
  {
    get
    {
      UserDefaults.standard.bool(forKey: "scrollPreview")
    }
    
    set
    {
      UserDefaults.standard.set(newValue, forKey: "scrollPreview")
      if let menuItem = NSApplication.shared
                                     .mainMenu?.item(withTitle: "Editor")?
                                     .submenu?.item(withTitle: "Scroll Preview")
      {
        menuItem.state = newValue ? .on : .off
      }
      else
      {
        Log.error("Preference.scrollPreview.set did not get Editor->Scroll Preview menu item")
      }
    }
  }
  
  static var proofReadVoiceName: String
  {
    get
    {
      return readDefault(forkey: "proofReadVoiceName", notFoundReturn: "Samantha")
    }
    
    set
    {
      UserDefaults.standard.set(newValue, forKey: "proofReadVoiceName")
    }
  }
  
  static var proofReadVoiceRate: Float
  {
    get
    {
      let rate = UserDefaults.standard.float(forKey: "proofReadVoiceRate")
      return rate < 30  ? 30 : rate
    }
    
    set
    {
      UserDefaults.standard.set(newValue, forKey: "proofReadVoiceRate")
    }
  }
  
  static var editorOnLeft: Bool
  {
    get
    {
      return readDefault(forkey: "editorOnLeft", notFoundReturn: "t") == "t"
    }
    
    set
    {
      let s = newValue ? "t" : "f"
      UserDefaults.standard.set(s, forKey: "editorOnLeft")
    }
  }
  
  static var editorTheme: String
  {
    get
    {
      return readDefault(forkey: "editorTheme",
                 notFoundReturn: "default")
    }
    
    set
    {
      UserDefaults.standard.set(newValue, forKey: "editorTheme")
  
    }
  }
  
  
  static var previewCSS: String 
  {
    get
    {
      return readDefault(forkey: "previewCss", notFoundReturn: "style.epub.css")
    }
    
    set
    {
      UserDefaults.standard.set(newValue, forKey: "previewCss")
    }
  }
  
  static var editorFont: NSFont
  {
    get
    {
      if let face = UserDefaults.standard.string(forKey: "editorFontFace"),
         let size = UserDefaults.standard.string(forKey: "editorFontSize"),
         let font = NSFont(name: face, size: CGFloat(Float(size)!))
      {
        return font
      }
      else
      {
        return NSFont(name: "Menlo", size: 14)!
      }
    }
    
    set
    {
      UserDefaults.standard.set(newValue.fontName, forKey: "editorFontFace")
      UserDefaults.standard.set("\(newValue.pointSize)", forKey: "editorFontSize")
      Log.info("set user default editor font to \(newValue.fontName), \(newValue.pointSize)")
    }
  }
  
  static var askBeforeCopyImage: Bool
  {
    get {readDefault(forkey: "askBeforeCopyImage", notFoundReturn: "t") == "t" ? true : false}
    set
    {
      UserDefaults.standard.set(newValue ? "t" : "f", forKey: "askBeforeCopyImage")
    }
  }
}
