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
    
    editorView.VC = self
    editorView.setup()
    
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
    UserDefaults.standard.set(cssSelector.stringValue, forKey: "previewCss")
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
    func clean(_ s: String, _ lengthThreshold: Int = 50) -> String
    {
      func chop() -> String
      {
        if s.count <= lengthThreshold
        {
          return s
        }
        else
        {
          let i = s.index(s.startIndex, offsetBy: 0)
          let j = s.index(s.startIndex, offsetBy: lengthThreshold)
          return String(s[i...j])
        }
      }
      
      let r = chop().replacingOccurrences(of: "\'", with: "\\\'").filter {!"*#_-".contains($0)} 
      return r.trim().javaScriptEscapedString()
    }
    
    if !Preference.scrollPreview
    {
      return
    }
    
    if let paragraph = editorView.textBlockAtCursor() 
    {
      webView.scrollToParagrah(withSubString: clean(paragraph),
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



/*
 class WebPrinter: NSObject, WebFrameLoadDelegate {

     let window: NSWindow
     var printView: WebView?
     let printInfo = NSPrintInfo.shared

     init(window: NSWindow) {
         self.window = window
         printInfo.topMargin = 30
         printInfo.bottomMargin = 15
         printInfo.rightMargin = 0
         printInfo.leftMargin = 0
     }

     func printHtml(_ html: String) {
         let printViewFrame = NSMakeRect(0, 0, printInfo.paperSize.width, printInfo.paperSize.height)
         printView = WebView(frame: printViewFrame, frameName: "printFrame", groupName: "printGroup")
         printView!.shouldUpdateWhileOffscreen = true
         printView!.frameLoadDelegate = self
         printView!.mainFrame.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
     }

     func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
         if sender.isLoading {
             return
         }
         if frame != sender.mainFrame {
             return
         }
         if sender.stringByEvaluatingJavaScript(from: "document.readyState") == "complete" {
             sender.frameLoadDelegate = nil
             let printOperation = NSPrintOperation(view: frame.frameView.documentView, printInfo: printInfo)
             printOperation.runModal(for: window, delegate: window, didRun: nil, contextInfo: nil)
         }
     }
 }
 */
