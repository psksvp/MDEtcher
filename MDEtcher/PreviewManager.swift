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
    \(loopHead)
    {
      if(x[i].textContent.indexOf(\(s)) >= 0)
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
    
    let cssName = readDefault(forkey: "previewCss",
                              notFoundReturn: "style.epub.css")
          
    vc.cssSelector.selectItem(withObjectValue: cssName)
    putCheckmark(title: cssName, inMenu: previewCssMenu!)
    
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
    
    guard !md.isEmpty  else
    {
      Log.warn("Editor is empty. Preview is ignored")
      return
    }
    
    updating = true
    VC.busyView.animates = true
    
    
    let cssName = readDefault(forkey: "previewCss",
                              notFoundReturn: "style.epub.css")
    
    DispatchQueue.global(qos: .background).async
    {
      if let html = Pandoc.toHTML(markdown: md, css: cssName)
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
}
