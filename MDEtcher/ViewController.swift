//
//  ViewController.swift
//  MDEtcher
//
//  Created by psksvp on 6/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import Cocoa
import WebKit
import CommonSwift


class ViewController: NSViewController
{
  @IBOutlet weak var mainView: NSSplitView!
  @IBOutlet weak var editorView: MarkDownEditorView!
  @IBOutlet weak var previewView: PreviewView!
  @IBOutlet weak var busyView: NSImageView!
  
  @IBOutlet weak var editorClipView: NSClipView!
  @IBOutlet weak var cssSelector: NSComboBox!
  @IBOutlet weak var outlineSelector: NSPopUpButton!

  ////////////////////////////////
  /// NSViewController
  //////////////////////////////
  override func viewDidLoad()
  {
    super.viewDidLoad()
    busyView.image = Resource.busyAnimation
    editorView.setup(self)
    previewView.setup(self)
    
    // get menu to update accordingly
    // funcking confusing, TODO: Refactor
    Preference.scrollPreview = Preference.scrollPreview
    
    self.editorClipView.postsBoundsChangedNotifications = true
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(editorVisibleViewChanged),
                                           name: NSClipView.boundsDidChangeNotification,
                                           object: self.editorClipView)
  }

  override var representedObject: Any?
  {
    didSet
    {
    // Update the view, if already loaded.
    }
  }
  
 
  func runBusyIcon(_ run: Bool)
  {
    busyView.animates = run
  }
  
  
  /////////
  // it should not be done this way
  var documentURL: URL?
  {
    get
    {
      return (self.view.window?.windowController?.document as? Document)?.fileURL
    }
  }
  
  ///
  @objc func editorVisibleViewChanged(_ :Notification)
  {
    if Preference.scrollPreview
    {
      // sync scrolling
      guard previewView.documentHeight > 0 else {return}
  
      let h1 = Float(editorClipView.documentRect.height)
      let h2 = Float(previewView.documentHeight)
      let p1 = Float(editorClipView.bounds.origin.y)
      let p2 = (h2 * p1) / h1
      //print(p1, p2)
      previewView.scrollToVerticalPoint(Int(round(p2)))
    }
  }
  
  
  //////////////////////////////////////
  // UI action
  //////////////////////////////////////
  
  @IBAction func cssPreviewSelected(_ sender: Any)
  {
    Preference.previewCSS = cssSelector.stringValue
    previewUpdate(self)
    Log.info("updating preview css to \(cssSelector.stringValue)")
  }
  
  @IBAction func outlineItemSelected(_ sender: Any)
  {
    if let selectedItem = outlineSelector.selectedItem,
       let loc = editorView.string.intIndex(of: selectedItem.title.trimmingCharacters(in: .whitespacesAndNewlines))
    {
      // editor view
      let r = NSMakeRange(loc, 0)
      editorView.scrollRangeToVisible(r)
      editorView.setSelectedRange(r) // move cursor there
      
      // preview view
      previewView.scrollToAnchor(selectedItem.title.lowercased())
    }
    else
    {
      Log.warn("header not found")
    }
  }
  

  //////////////////////////////////////
  /// Menus actions
  //////////////////////////////////////
  
  @IBAction func previewCopyHTML(_ sender: Any)
  {
    //previewView.copyHTML()
    let html = previewView.html
    NSPasteboard.general.declareTypes([.string], owner: self)
    NSPasteboard.general.setString(html, forType: .string)
  }
  
  @IBAction func previewUpdate(_ sender: Any)
  {
    previewView.update(md: editorView.string)
  }
  
  @IBAction func editorFont(_ sender: Any)
  {
    self.editorView.showFontPanel()
  }
  
  @IBAction func syncPreviewWithEditor(_ sender: Any)
  {
    guard Preference.scrollPreview else
    {
      return
    }

    if let paragraph = editorView.textBlockAtCursor()
    {
      previewView.syncWithEditor(atParagraph: paragraph)
    }
  }
  
  @IBAction func printPreview(_ sender: Any)
  {
    self.previewView.print()
  }
  
  @IBAction func exportPDF(_ sender: Any)
  {
    guard let _ = Resource.xelatexPath else
    {
      Log.info("export PDF, user did not provide path to xelatex")
      return
    }
    
    exportFile("pdf")
    {
      path in
      let md = self.editorView.string
      WorkPrograssWindowController.shared.show("Exporting: \(path)")
      DispatchQueue.global(qos: .background).async
      {
        Pandoc.write(md, toPDF: path)
      }
    }
  }
  
  @IBAction func exportAiff(_ send: Any)
  {
    exportFile("aiff")
    {
      path in
      WorkPrograssWindowController.shared.show("Exporting: \(path)")
      self.editorView.proofReader.text = self.editorView.string
      DispatchQueue.global(qos: .background).async
      {
        self.editorView.proofReader.start(toURL: URL(fileURLWithPath: path))
      }
      WorkPrograssWindowController.shared.hide()
    }
  }
  
  @IBAction func exportHTML(_ sender: Any)
  {
    let cssName = readDefault(forkey: "previewCss",
                              notFoundReturn: "style.epub.css")
    let md = editorView.string
    
    exportFile("html")
    {
      path in
      DispatchQueue.global(qos: .background).async
      {
        Pandoc.write(md, toHTMLFileAtPath: path,
                                 usingCSS: cssName)
        DispatchQueue.main.async
        {
          WorkPrograssWindowController.shared.hide()
        }
      }
    }
  }
  
  @IBAction func editorScrollingPreview(_ sender: Any)
  {
    Preference.scrollPreview = !Preference.scrollPreview
  }
  
  @IBAction func proofReaderAction(_ sender: Any)
  {
    if let mi = sender as? NSMenuItem
    {
      editorView.proofReader.handleAction(mi.title)
    }
  }
  
  @IBAction func hideShowPreview(_ sender: NSMenuItem)
  {
    if sender.title.lowercased().contains("hide")
    {
      mainView.setPosition(mainView.frame.size.width, ofDividerAt: 0)
      sender.title = "Show Preview"
    }
    else
    {
      mainView.setPosition(mainView.frame.size.width / 2, ofDividerAt: 0)
      sender.title = "Hide Preview"
    }
  }
  
  func exportFile(_ type: String, exportCode: @escaping (_ path: String) -> Void)
  {
    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = "\(self.view.window!.title).\(type)"
    savePanel.allowedFileTypes = ["\(type)"]
    savePanel.beginSheetModal(for: self.view.window!)
    {
      respond in
      if respond == NSApplication.ModalResponse.OK
      {
        guard let url = savePanel.url else {return}
        WorkPrograssWindowController.shared.show("Exporting: \(url.path)")

        exportCode(url.path)
      }
    }
  }
}




