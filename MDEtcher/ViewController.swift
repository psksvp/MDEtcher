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


class ViewController: NSViewController, WKNavigationDelegate
{
  @IBOutlet weak var mainView: NSSplitView!
  @IBOutlet weak var editorView: MarkDownEditorView!
  @IBOutlet weak var webView: WKWebView!
  @IBOutlet weak var busyView: NSImageView!
  
  @IBOutlet weak var editorClipView: NSClipView!
  @IBOutlet weak var cssSelector: NSComboBox!
  @IBOutlet weak var outlineSelector: NSPopUpButton!

  private var visibleTop:CGFloat = 0.0
  private var previewManager: PreviewManager!
  

  ////////////////////////////////
  /// NSViewController
  //////////////////////////////
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    editorView.setup(self)
    previewManager = PreviewManager(self)
    
    webView.navigationDelegate = self
    
    busyView.image = Resource.busyAnimation
    
    // get menu to update accordingly
    // funcking confusing, TODO: Refactor
    Preference.scrollPreview = Preference.scrollPreview
    
    // init clipview top Y pos to detect scroll up or down
    visibleTop = editorClipView.bounds.minY
    
  }

  override var representedObject: Any?
  {
    didSet
    {
    // Update the view, if already loaded.
    }
  }
  
  // WkWebView didFinish
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
  {
    self.syncPreviewWithEditor(self)
    // SHOULD DO? : if the above stmt fail, do below
//    if let selectedTitleInOutline = self.outlineSelector.selectedItem
//    {
//      self.webView.scrollToAnchor(selectedTitleInOutline.title)
//    }
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
      webView.scrollToAnchor(selectedItem.title.lowercased())
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
    webView.evaluateJavaScript("document.documentElement.outerHTML.toString()")
    {
      (data, error) in

      if let d = data,
         let html = d as? String
      {
        NSPasteboard.general.declareTypes([.string], owner: self)
        NSPasteboard.general.setString(html, forType: .string)
      }
      else
      {
        Log.warn("Did not copy HTML")
        dump(error)
      }
    }
    
  }
  
  @IBAction func previewUpdate(_ sender: Any)
  {
    previewManager.updatePreview(md: editorView.string)
  }
  
  @IBAction func editorFont(_ sender: Any)
  {
    NSFontManager.shared.orderFrontFontPanel(self)
  }
  
  @IBAction func syncPreviewWithEditor(_ sender: Any)
  {
    guard Preference.scrollPreview else
    {
      return
    }
    
    if let paragraph = editorView.textBlockAtCursor() 
    {
      previewManager.syncWithEditor(atParagraph: paragraph,
                                    searchReverse: editorClipView.bounds.minY < visibleTop)
      visibleTop = editorClipView.bounds.minY
    }
  }
  
  @IBAction func exportPDF(_ send: Any)
  {
    let md = editorView.string
    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = "\(self.view.window!.title).pdf"
    savePanel.allowedFileTypes = ["pdf"]
    savePanel.beginSheetModal(for: self.view.window!)
    {
      respond in
      if respond == NSApplication.ModalResponse.OK
      {
        guard let url = savePanel.url else {return}
        WorkPrograssWindowController.shared.show("Exporting: \(url.path)")
        DispatchQueue.global(qos: .background).async
        {
          Pandoc.write(md, toPDF: url.path)
        }
      }
    }
  }
  
  @IBAction func exportAiff(_ send: Any)
  {
    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = "\(self.view.window!.title).aiff"
    savePanel.allowedFileTypes = ["aiff"]
    savePanel.beginSheetModal(for: self.view.window!)
    {
      respond in
      if respond == NSApplication.ModalResponse.OK
      {
        guard let url = savePanel.url else {return}
        self.editorView.proofReader.text = self.editorView.string
        WorkPrograssWindowController.shared.show("Exporting \(url.path)")
        DispatchQueue.global(qos: .background).async
        {
          self.editorView.proofReader.start(toURL: url)
        }
      }
    }
  }
  
  @IBAction func exportHTML(_ sender: Any)
  {
    let cssName = readDefault(forkey: "previewCss",
                              notFoundReturn: "style.epub.css")
    let md = editorView.string

    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = "\(self.view.window!.title).html"
    savePanel.allowedFileTypes = ["html"]
    savePanel.beginSheetModal(for: self.view.window!)
    {
      respond in
      if respond == NSApplication.ModalResponse.OK
      {
        guard let url = savePanel.url else {return}
        DispatchQueue.global(qos: .background).async
        {
          Pandoc.write(md, toHTMLFileAtPath: url.path,
                                usingCSS: cssName)
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
}




