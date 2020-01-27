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
import Highlighter

class ViewController: NSViewController, NSTextViewDelegate, WKNavigationDelegate
{
  @IBOutlet weak var mainView: NSSplitView!
  @IBOutlet weak var editorView: MarkDownEditorView!
  @IBOutlet weak var webView: WKWebView!
  @IBOutlet weak var busyView: NSImageView!
  
  @IBOutlet weak var editorClipView: NSClipView!
  

  @IBOutlet weak var cssSelector: NSComboBox!
  @IBOutlet weak var outlineSelector: NSPopUpButton!
  
  private var previewCssMenu:NSMenu? = nil
  private var editorThemeMenu:NSMenu? = nil
  
  private let textStorage = CodeAttributedString()
  private let pandoc = Pandoc()
  private var updatingPreview = false
  private var visibleTop:CGFloat = 0.0
  
  //private let previewRenderingAnimationView = NSImageView(image: pandoc.busyImage!)

  private func setupEditor()
  {
    textStorage.language = "Markdown"

    if let lm = editorView.layoutManager
    {
      textStorage.addLayoutManager(lm)
      lm.replaceTextStorage(textStorage)
      
      editorView.delegate = self
      editorView.autoresizingMask = [.width,.height]
      editorView.translatesAutoresizingMaskIntoConstraints = true
      
      
      editorThemeMenu?.removeAllItems()
      for t in textStorage.highlightr.availableThemes()
      {
        let i = NSMenuItem(title: t, action: #selector(editorThemeSelect), keyEquivalent: "")
        editorThemeMenu?.addItem(i)
      }
      
      setupTheme()
    }
    else
    {
      Log.error("editorView had no layoutManager")
    }
  }
  
  private func setupTheme()
  {
    let themeName = readDefault(forkey: "editorTheme",
                                notFoundReturn: "default")
    
    Log.info("setting editor theme to \(themeName)")
    putCheckmark(title: themeName, inMenu: editorThemeMenu!)
    textStorage.highlightr.setTheme(to: themeName)
    
    //Make sure the cursor won't be invisible
    let bgColor = textStorage.highlightr.theme.themeBackgroundColor.usingColorSpace(NSColorSpace.deviceRGB)!
    editorView.backgroundColor = bgColor
    editorView.insertionPointColor = NSColor(red: 1.0 - bgColor.redComponent,
                                             green: 1.0 - bgColor.greenComponent,
                                             blue: 1.0 - bgColor.blueComponent,
                                             alpha: 1.0)
    
    Log.info("editor background color is set to \(editorView.backgroundColor)")
    Log.info("editor cursor color is set to \(editorView.insertionPointColor)")
    
    textStorage.highlightr.theme.codeFont = NSFont(name: "PT Mono", size: 16)
    textStorage.highlightr.theme.boldCodeFont = NSFont(name: "PT Mono", size: 16)
    textStorage.highlightr.theme.italicCodeFont = NSFont(name: "PT Mono", size: 16)
  }
  
  private func setupCssSeletor()
  {
    if let rsc = Bundle.main.resourceURL,
       let cssfiles = FS.contentsOfDirectory("\(rsc.path)/pandoc/css")
    {
      cssSelector.removeAllItems()
      cssSelector.addItems(withObjectValues: cssfiles)
      
      previewCssMenu?.removeAllItems()
      for css in cssfiles
      {
        let menuItem = NSMenuItem(title: css,
                                  action: #selector(cssPreviewStyleMenuSelected),
                                  keyEquivalent: "")
        previewCssMenu?.addItem(menuItem)
      }
      
      let cssName = readDefault(forkey: "previewCss",
                                notFoundReturn: "style.epub.css")
            
      cssSelector.selectItem(withObjectValue: cssName)
      putCheckmark(title: cssName, inMenu: previewCssMenu!)
    }
  }
  
  ////////////////////////////////////
  func updateOutline(md: String)
  {
    DispatchQueue.global(qos: .background).async
    {
       if let ol = Markdown.herderOutline(md)
       {
         DispatchQueue.main.async
         {
           let selectedTitle = self.outlineSelector.selectedItem?.title
           
           self.outlineSelector.removeAllItems()
           self.outlineSelector.addItems(withTitles: ol)
          
           if let title = selectedTitle
           {
             self.outlineSelector.selectItem(withTitle: title)
           }
         }
       }
       else
       {
         Log.info("updating outline did not update, because outline is empty")
       }
    }
  }

  ////////////////////////////////
  /// NSViewController
  //////////////////////////////
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    editorView.viewController = self
    
    if let previewMenu = NSApplication.shared.mainMenu?.item(withTitle: "Preview"),
       let previewSubMenu = previewMenu.submenu,
       let previewStyleMenu = previewSubMenu.item(withTitle: "Style")?.submenu
    {
      previewCssMenu = previewStyleMenu
    }
    else
    {
      Log.error("Fail to get reference of Preview->Style menu")
    }
    
    
    if let editorMenu = NSApplication.shared.mainMenu?.item(withTitle: "Editor"),
       let themeSubMenu = editorMenu.submenu,
       let themeListMenu = themeSubMenu.item(withTitle: "Theme")?.submenu
    {
      editorThemeMenu = themeListMenu
    }
    else
    {
      Log.error("Fail to get reference of Editor->Theme menu")
    }
    
    ////////
    setupEditor()
    setupCssSeletor()
    self.outlineSelector.removeAllItems()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(outlineWillOpen),
                                           name: NSPopUpButton.willPopUpNotification,
                                           object: nil)
    
    webView.navigationDelegate = self
    
    if let busyImage = pandoc.busyImage
    {
      busyView.image = busyImage
    }
    else
    {
      Log.error("busy Image is missing")
    }
    
    
    // get menu to update accordingly
    Preference.scrollPreview = Preference.scrollPreview
    
    // init clipview top Y pos to detect scroll up or down
    visibleTop = editorClipView.bounds.minY
    
    //turn off stupid substitution
    if editorView.isAutomaticQuoteSubstitutionEnabled
    {
      editorView.toggleAutomaticQuoteSubstitution(self)
    }
  }

  override var representedObject: Any?
  {
    didSet
    {
    // Update the view, if already loaded.
    }
  }
  
  ////////////////
  @objc func outlineWillOpen(_ sender: Any)
  {
    updateOutline(md: editorView.string)
  }
  
  ////////////////
  @objc func cssPreviewStyleMenuSelected(_ sender: NSMenuItem)
  {
    Log.info("\(sender.title) Selected")
    cssSelector.selectItem(withObjectValue: sender.title)
    putCheckmark(item: sender, inMenu: previewCssMenu!)
    cssPreviewSelected(self)
  }
  
  @objc func editorThemeSelect(_ sender: NSMenuItem)
  {
    UserDefaults.standard.set(sender.title, forKey: "editorTheme")
    putCheckmark(item: sender, inMenu: editorThemeMenu!)
    setupTheme()
    Log.info("updating editor theme to \(sender.title)")
  }
  
  // WkWebView didFinish
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
  {
    self.syncWithEditor(self)
//    if let selectedTitleInOutline = self.outlineSelector.selectedItem
//    {
//      self.webView.scrollToAnchor(selectedTitleInOutline.title)
//    }
  }
  
  //NSTextView
  func textDidChange(_ notification: Notification)
  {
    //NSLog("------Text did change")
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
    if updatingPreview
    {
      Log.info("preview updating is running. Do nothing")
      return
    }
    
    let md = editorView.string
    if md.isEmpty
    {
      Log.warn("Editor is empty. Preview is ignored")
      return
    }
    
    updatingPreview = true
    busyView.animates = true
    
    
    let cssName = readDefault(forkey: "previewCss",
                              notFoundReturn: "style.epub.css")
    
    DispatchQueue.global(qos: .background).async
    {
      if let html = self.pandoc.toHTML(markdown: md, css: cssName)
      {
        DispatchQueue.main.async
        {
          self.webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
          self.busyView.animates = false
          self.updatingPreview = false
        }
      }
      else
      {
        Log.error("Preview Fail")
      }
    }
  }
  
  @IBAction func editorFont(_ sender: Any)
  {
    NSFontManager.shared.orderFrontFontPanel(self)
  }
  
  @IBAction func syncWithEditor(_ sender: Any)
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
    
    if let paragraph = paragraphAtCursorIn(textView: editorView)
    {
      webView.scrollToParagrah(withSubString: clean(paragraph),
                               searchReverse: editorClipView.bounds.minY < visibleTop)
      
      visibleTop = editorClipView.bounds.minY
    }
  }
  
  @IBAction func exportPDF(_ send: Any)
  {
    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = "\(self.view.window!.title).pdf"
    savePanel.allowedFileTypes = ["pdf"]
    savePanel.beginSheetModal(for: self.view.window!)
    {
      respond in
      if respond == NSApplication.ModalResponse.OK
      {
        guard let url = savePanel.url else {return}
        DispatchQueue.global(qos: .background).async
        {
          self.pandoc.write(self.editorView.string,
                            toPDF: url.path)
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
          self.pandoc.write(md, toHTMLFileAtPath: url.path,
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
