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
  
  static var editorTheme: String = ""
  static var previewCSS: String = ""
}
