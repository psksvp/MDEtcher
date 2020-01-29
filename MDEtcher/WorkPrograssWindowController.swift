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
  @IBOutlet weak var doneButton: NSButton!
  @IBOutlet weak var busyImage: NSImageView!
  @IBOutlet var messageTextView: NSTextView!
  
  var message: String
  {
    get { return messageTextView.string}
    set
    {
      messageTextView.string = newValue
      messageTextView.scrollLineDown(self)
    }
  }
  
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
    busyImage.image = Pandoc.shared.busyImage
  }
  
  func show(_ title: String)
  {
    self.window!.level = .mainMenu
    self.window!.title = title
    self.window!.orderFront(self)
    busyImage.animates = true
  }
  
  func hide()
  {
    self.window!.orderOut(self)
    doneButton.isEnabled = false
    busyImage.animates = false
  }
  
  func enableDoneButton()
  {
    doneButton.isEnabled = true
  }
  
  @IBAction func doneButtonPushed(_ sender: Any)
  {
    hide()
  }
}
