//
//  WorkPrograssWindowController.swift
//  MDEtcher
//
//  Created by psksvp on 28/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Cocoa

class WorkPrograssWindowController: NSWindowController
{
  @IBOutlet weak var infoText: NSTextField!
  
  private static var _one:WorkPrograssWindowController? = nil
  static var shared:WorkPrograssWindowController
  {
    get
    {
      if let _ = _one
      {
        return _one!
      }
      else
      {
        _one = WorkPrograssWindowController()
        return _one!
      }
    }
  }
  
  override var windowNibName: NSNib.Name?
  {
    return "WorkPrograssWindowController"
  }
  
  override func windowDidLoad()
  {
    super.windowDidLoad()
  }
  
  func show(_ title: String)
  {
    self.window!.title = title
    self.window!.orderFront(self)
  }
  
  func hide()
  {
    self.window!.orderOut(self)
  }
    
}
