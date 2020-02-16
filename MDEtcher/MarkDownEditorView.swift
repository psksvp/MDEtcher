//
//  MarkDownEditorView.swift
//  MDEtcher
//
//  Created by psksvp on 9/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import Cocoa
import CommonSwift
import Highlighter


extension NSTextView
{
  func textBlock(atRange r:NSRange) -> String?
  {
    guard let textStorage = self.textStorage else {return nil}
    let text = textStorage.string
    guard let f = Range(r, in: text) else {return nil}
    let pr = text.paragraphRange(for: f)
    
    if self.string[pr].trim().count > 0
    {
      return String(self.string[pr])
    }
    else
    {
      return nil
    }
  }
  
  func textBlockAtCursor() -> String?
  {
    textBlock(atRange: self.selectedRange())
  }
}

/////////////////////////////////////////////////////
class MarkDownEditorView: NSTextView, NSTextViewDelegate
{
  private let highlightedCS = CodeAttributedString()
  private var editorThemeMenu:NSMenu? = nil
  private let speechSyn: NSSpeechSynthesizer = NSSpeechSynthesizer(voice: nil)!
  private var _proofReader: TextViewProofReader? = nil
  
  private var VC: ViewController!
  
  var proofReader: TextViewProofReader
  {
    get
    {
      if let p = _proofReader
      {
        return p
      }
      else
      {
        _proofReader = TextViewProofReader(forTextView: self)
        return _proofReader!
      }

    }
  }
  
  override func mouseDown(with event: NSEvent)
  {
    super.mouseDown(with: event)
    proofReader.stop() // if it is running
    VC.syncPreviewWithEditor(self)
  }
  
  func setup(_ vc: ViewController)
  {
    VC = vc
    
    let draggedType = [NSPasteboard.PasteboardType.fileURL,
                       NSPasteboard.PasteboardType.URL]
    registerForDraggedTypes(draggedType)
    setupSyntaxHighlighter()
    setupOutline()
  }
  
  
  func setupOutline()
  {
    VC.outlineSelector.removeAllItems()
    VC.outlineSelector.addItem(withTitle: "Outline")
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(updateOutline),
                                           name: NSPopUpButton.willPopUpNotification,
                                           object: nil)
    
    updateOutline(self)
  }
  

  func setupSyntaxHighlighter()
  {
    highlightedCS.language = "Markdown"
    
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

    if let lm = self.layoutManager
    {
      highlightedCS.addLayoutManager(lm)
      lm.replaceTextStorage(highlightedCS)
      
      self.delegate = self
      self.autoresizingMask = [.width,.height]
      self.translatesAutoresizingMaskIntoConstraints = true
      
      editorThemeMenu?.removeAllItems()
      for t in highlightedCS.highlightr.availableThemes()
      {
        let i = NSMenuItem(title: t, action: #selector(editorThemeSelected), keyEquivalent: "")
        editorThemeMenu?.addItem(i)
      }
      
      // setup theme
      refreshTheme()
    }
    else
    {
      Log.error("editorView had no layoutManager")
    }
  }
  
  
  func refreshTheme()
  {
    let themeName = Preference.editorTheme
    
    Log.info("setting editor theme to \(themeName)")
    putCheckmark(title: themeName, inMenu: editorThemeMenu!)
    highlightedCS.highlightr.setTheme(to: themeName)
    
    //Make sure the cursor won't be invisible
    let bgColor = highlightedCS.highlightr.theme.themeBackgroundColor.usingColorSpace(NSColorSpace.deviceRGB)!
    self.backgroundColor = bgColor
    self.insertionPointColor = NSColor(red: 1.0 - bgColor.redComponent,
                                       green: 1.0 - bgColor.greenComponent,
                                       blue: 1.0 - bgColor.blueComponent,
                                       alpha: 1.0)
    
    Log.info("editor background color is set to \(self.backgroundColor)")
    Log.info("editor cursor color is set to \(self.insertionPointColor)")
    
    highlightedCS.highlightr.theme.setCodeFont(Preference.editorFont)

    //turn off stupid substitution
    if self.isAutomaticQuoteSubstitutionEnabled
    {
      self.toggleAutomaticQuoteSubstitution(self)
    }
    
    if self.isAutomaticDashSubstitutionEnabled
    {
      self.toggleAutomaticDashSubstitution(self)
    }
  }
  
  func showFontPanel()
  {
    let fm = NSFontManager.shared
    fm.target = self
    fm.action = #selector(fontChanged)
    NSFontManager.shared.setSelectedFont(Preference.editorFont, isMultiple: false)
    NSFontManager.shared.orderFrontFontPanel(self)
  }
  
  @objc func fontChanged(_ sender: Any)
  {
    if let font = NSFontManager.shared.selectedFont
    {
      Preference.editorFont = font
      self.refreshTheme()
    }
    else
    {
      Log.warn("there is no font selected?")
    }
  }
  
  @objc func editorThemeSelected(_ sender: NSMenuItem)
  {
    Preference.editorTheme = sender.title
    putCheckmark(item: sender, inMenu: editorThemeMenu!)
    refreshTheme()
    Log.info("updating editor theme to \(sender.title)")
  }
  
  @objc func updateOutline(_ sender: Any)
  {
    if false == self.string.isEmpty
    {
      fillOutline(self.string)
    }
  }
  
  func fillOutline(_ md: String)
  {
    DispatchQueue.global(qos: .background).async
    {
       if let ol = Markdown.headerOutline(md)
       {
         DispatchQueue.main.async
         {
           let selectedTitle = self.VC.outlineSelector.selectedItem?.title
           
           self.VC.outlineSelector.removeAllItems()
           self.VC.outlineSelector.addItems(withTitles: ol)
          
           if let title = selectedTitle,
              title != "Outline"
           {
             self.VC.outlineSelector.selectItem(withTitle: title)
             Log.info("select outline at title \(title)")
           }
           else
           {
             self.VC.outlineSelector.selectItem(at: 0)
             Log.info("select outline at index 0")
           }
         }
       }
       else
       {
         Log.info("updating outline did not update, because outline is empty")
       }
    }
  }
  
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation
  {
    NSLog(sender.description)
    
    return .copy
  }
  
  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool
  {
    func localImagePath(_ url: URL) -> String?
    {
      guard url.isFileURL else
      {
        Log.error("\(url) is not a fileURL")
        return nil
      }
      
      let images = ["jpg", "jpeg", "png", "gif"]
      guard images.contains(url.pathExtension.lowercased()) else
      {
        Log.error("file \(url) is not jpg, jpeg, png or gif")
        return nil
      }
      
      // make copy?
      if let docURL = VC.documentURL
      {
        if directoryPathOfFileURL(docURL) == directoryPathOfFileURL(url)
        {
          return url.lastPathComponent
        }
        else
        {
          let fileName = url.lastPathComponent
          // it's a mess, refact this shit
          if false == fileExists(fileName, inDirectory: directoryURL(ofFileURL: docURL))
          {
            let a = NSAlert()
            a.messageText = "file  \(fileName) is not in the same directory as the document file.\n\nCopy it in?"
            a.alertStyle = .informational
            a.addButton(withTitle: "OK")
            a.addButton(withTitle: "Cancel")
            a.showsSuppressionButton = true
            a.suppressionButton?.title = "Do this action next time."
            if .alertFirstButtonReturn == a.runModal()
            {
              if a.suppressionButton?.state == .on
              {
                Preference.askBeforeCopyImage = true
              }
              
              let dstURL = docURL.deletingLastPathComponent().appendingPathComponent(fileName)
              Log.info("going to copy \(fileName) into \(directoryPathOfFileURL(docURL))")
              try? FileManager.default.copyItem(at: url, to: dstURL)
              return dstURL.relativePath(from: directoryURL(ofFileURL: docURL))
            }
            else
            {
              if a.suppressionButton?.state == .off
              {
                Preference.askBeforeCopyImage = false
              }
            }
            
            return nil
          }
          else
          {
            // file is in subdir of the document file
            // so just create rel path to it.
            return url.relativePath(from: docURL.deletingLastPathComponent())
          }
        }
      }
      else
      { // file has not been saved
        return url.path
      }
    }
    
    
    if let url = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self],
                                                           options: nil)!.first as? URL,
       let localPath = localImagePath(url)
    {
      let insertionPt = self.selectedRanges[0].rangeValue
      let urlText = "![\(url.lastPathComponent)](\(localPath))"
      self.replaceCharacters(in: insertionPt, with: urlText)
    }
    
    return true
  }
  
  func format(_ type: String)
  {
    let selected = self.selectedRange()
    guard let text = self.string.substring(with: selected) else
    {
      Log.warn("nothing selected")
      return
    }
    
    switch type.lowercased()
    {
      case "$mathjax$"   : self.replaceCharacters(in: selected, with: "$\(text)$")
      case "$$mathjax$$" : self.replaceCharacters(in: selected, with: "$$\(text)$$")
      
      default : Log.warn("unknown format type \(type)")
    }
  }
}// MarkDownEditorView



  



//      ulrs.forEach
//      {
//        // Do something with the file paths.
//        if let url = $0 as? URL
//        {
//          print(url.path)
//        }
//      }
