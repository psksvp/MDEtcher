//
//  FileSelectorController.swift
//  MDEtcher
//
//  Created by psksvp on 3/2/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Cocoa
import CommonSwift

class FileSelectorController: NSWindowController
{
  static private var one: FileSelectorController? = nil
  static var shared: FileSelectorController
  {
    get
    {
      if let _ = one
      {
        return one!
      }
      else
      {
        one = FileSelectorController()
        return one!
      }
    }
  }
  
  @IBOutlet weak var messageTextField: NSTextFieldCell!
  @IBOutlet weak var filePathTextField: NSTextField!
  
  var messageText: String = ""
  var filePath: String = ""
  
  func showModal() -> NSApplication.ModalResponse
  {
    let result = NSApplication.shared.runModal(for: self.window!)
    self.window!.close()
    return result
  }
  
  override var windowNibName: NSNib.Name?
  {
    return "FileSelectorController"
  }
  
  
  override func windowDidLoad()
  {
    super.windowDidLoad()
    Log.info("FileSelectorController.windowDidLoad()")
    messageTextField.stringValue = messageText
    filePathTextField.stringValue = filePath
  }
  
  @IBAction func showFileOpenDialog(_ sender: Any)
  {
    let openPanel = NSOpenPanel()
    openPanel.title = messageText
    openPanel.message = messageText
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = false
    openPanel.canCreateDirectories = false
    openPanel.canChooseFiles = true
    openPanel.beginSheetModal(for: self.window!)
    {
      respond in
      if respond == .OK
      {
        self.filePath = openPanel.url!.path
        self.filePathTextField.stringValue = openPanel.url!.path
      }
    }
  }
  
  @IBAction func okPushed(_ sender: Any)
  {
    let path = self.filePathTextField.stringValue
    if FileManager.default.fileExists(atPath: path)
    {
      self.filePath = path
      NSApplication.shared.stopModal(withCode: .OK)
    }
    else
    {
      let a = NSAlert()
      a.messageText = "file  \(path) does not exists"
      a.alertStyle = .warning
      a.addButton(withTitle: "OK")
      a.beginSheetModal(for: self.window!)
    }
  }
  
  @IBAction func cancelPushed(_ sender: Any)
  {
    NSApplication.shared.stopModal(withCode: .cancel)
  }
}
