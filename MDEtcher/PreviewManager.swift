//
//  PreviewManager.swift
//  MDEtcher
//
//  Created by psksvp on 31/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import AppKit
import CommonSwift
import WebKit

extension WKWebView
{
  /// does not work eval JS is async
  var html: String?
  {
    get
    {
      var htmlString: String? = nil
      let sem = DispatchSemaphore(value: 0)
      // eval JS is async, so need sem to wait for it
      // aka make it a sync call
      self.evaluateJavaScript("document.documentElement.outerHTML.toString()")
      {
        (data, error) in

        if let d = data,
           let html = d as? String
        {
          htmlString = html
        }
        else
        {
          Log.warn("Did not copy HTML")
          dump(error)
        }
        sem.signal()
      }
      
      // wait for sem
      _ = sem.wait(timeout: .distantFuture)
      return htmlString
    }
  }
  
  func scrollToAnchor(_ s:String) -> Void
  {
    let anchor = "\"#\(s.lowercased().trim().replacingOccurrences(of: " ", with: "-"))\""
    let js = "location.hash = \(anchor);"
    //Log.info("about to eval javascript \(js)")
    self.evaluateJavaScript(js)
    {
      (sender, error) in
      dump(error)
    }
  }
  
  func scrollToParagrah(withSubString s: String, searchReverse: Bool = false) -> Void
  {
    let loopHead = searchReverse ? "for(var i = x.length - 1; i >= 0; i--)" :
                                   "for(var i = 0; i < x.length; i++)"
    let js = """
    var bgColor = document.body.style.backgroundColor;
    var x = document.querySelectorAll("p, q, li, h1, h2, h3");
    var s = \(s)
    \(loopHead)
    {
      if(x[i].textContent.indexOf(s) >= 0)
      {
        x[i].scrollIntoView({behavior: "smooth", block: "center", inline: "nearest"});
        x[i].style.backgroundColor = "Azure";
        break;
      }
      else
      {
        x[i].style.backgroundColor = bgColor;
      }
    }
    """
    //Log.info("about to eval javascript\n\(js)")
    self.evaluateJavaScript(js)
    {
      (sender, error) in
      dump(error)
    }
  }
}

/////////////////////////////////////////////////////////
///
/////////////////////////////////////////////////////////
class PreviewManager : NSObject
{
  var previewCssMenu: NSMenu?
  {
    get
    {
      if let previewMenu = NSApplication.shared.mainMenu?.item(withTitle: "Preview"),
         let previewSubMenu = previewMenu.submenu,
         let previewStyleMenu = previewSubMenu.item(withTitle: "Style")?.submenu
      {
        return previewStyleMenu
      }
      else
      {
        Log.error("Fail to get reference of Preview->Style menu")
        return nil
      }
    }
  }
  
  private var VC: ViewController!
  private var updating = false
  
  init(_ vc: ViewController)
  {
    super.init()
  
    VC = vc
    let cssFiles = Resource.contents(ofResourceFolder: "css")!
    vc.cssSelector.removeAllItems()
    vc.cssSelector.addItems(withObjectValues: cssFiles)
    
    previewCssMenu?.removeAllItems()
    for css in cssFiles
    {
      let menuItem = NSMenuItem(title: css,
                                action: #selector(cssPreviewStyleMenuSelected),
                                keyEquivalent: "")
      previewCssMenu?.addItem(menuItem)
    }
       
    vc.cssSelector.selectItem(withObjectValue: Preference.previewCSS)
    putCheckmark(title: Preference.previewCSS, inMenu: previewCssMenu!)
    vc.cssSelector.numberOfVisibleItems = cssFiles.count >= 30 ? 30 : cssFiles.count
  }
  
  @objc func cssPreviewStyleMenuSelected(_ sender: NSMenuItem)
  {
    Log.info("\(sender.title) Selected")
    VC.cssSelector.selectItem(withObjectValue: sender.title)
    putCheckmark(item: sender, inMenu: previewCssMenu!)
    updatePreview(md: VC.editorView.string)
  }
  
  
  func updatePreview(md: String)
  {
    guard !updating else
    {
      Log.info("preview updating is running. Do nothing")
      return
    }
    
    guard !md.isEmpty else
    {
      Log.warn("Editor is empty. Preview is ignored")
      return
    }
    
    updating = true
    VC.busyView.animates = true
    
    
    let cssName = readDefault(forkey: "previewCss",
                              notFoundReturn: "style.epub.css")
    
    let rscPath: String? = VC.documentURL != nil ? directoryPathOfFileURL(VC.documentURL!) : nil
    
    DispatchQueue.global(qos: .background).async
    {
      if let html = Pandoc.toHTML(markdown: md, css: cssName, filesResourcePath: rscPath)
      {
        DispatchQueue.main.async
        {
          self.VC.webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
          self.VC.busyView.animates = false
          self.updating = false
        }
      }
      else
      {
        Log.error("Preview Fail")
      }
    }
  }
  
  func syncWithEditor(atParagraph paragraph: String, searchReverse sr: Bool)
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
    
    VC.webView.scrollToParagrah(withSubString: clean(paragraph),
                             searchReverse: sr)
  }
  
  func print()
  {    
    let rscPath: String? = VC.documentURL != nil ? directoryPathOfFileURL(VC.documentURL!) : nil

    if let html = Pandoc.toHTML(markdown: VC.editorView.string,
                                css: Preference.previewCSS,
                                filesResourcePath: rscPath,
                                previewing: false)
    {
      let path = "\(FileManager.default.temporaryDirectory.path)/p.html"
      FS.writeText(inString: html, toPath: path)
      if FileManager.default.fileExists(atPath: path)
      {
        OS.spawn(["/usr/bin/open", "-a", "Safari.app", path], nil)
      }
      else
      {
        DispatchQueue.main.async
        {
          let a = NSAlert()
          a.messageText = "Print Fail, fail to write to\n\(path)"
          a.alertStyle = .warning
          a.addButton(withTitle: "OK")
          a.beginSheetModal(for: self.VC.view.window!)
        }
      }
    }
  }
  
}



//class WebPrinter: NSObject, WebFrameLoadDelegate
//{
//    let window: NSWindow
//    var printView: WebView?
//    let printInfo = NSPrintInfo.shared
//
//    init(window: NSWindow)
//    {
//        self.window = window
//        printInfo.topMargin = 30
//        printInfo.bottomMargin = 15
//        printInfo.rightMargin = 0
//        printInfo.leftMargin = 0
//      print("0000000")
//    }
//
//    func printHtml(_ html: String)
//    {
//        let printViewFrame = NSMakeRect(0, 0, printInfo.paperSize.width, printInfo.paperSize.height)
//        printView = WebView(frame: printViewFrame, frameName: "printFrame", groupName: "printGroup")
//        printView!.shouldUpdateWhileOffscreen = true
//        printView!.frameLoadDelegate = self
//        printView!.mainFrame.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
//      print("111111111")
//    }
//
//    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!)
//    {
//        if sender.isLoading {
//          print("2222222")
//            return
//        }
//        if frame != sender.mainFrame {
//          print("333333")
//            return
//        }
//        if sender.stringByEvaluatingJavaScript(from: "document.readyState") == "complete" {
//          print("4444444")
//            sender.frameLoadDelegate = nil
//            let printOperation = NSPrintOperation(view: frame.frameView.documentView, printInfo: printInfo)
//            printOperation.runModal(for: window, delegate: window, didRun: nil, contextInfo: nil)
//        }
//    }
//}

