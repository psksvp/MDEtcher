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
      return String(self.string[pr]).trim()
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
  
  override func scrollWheel(with event: NSEvent)
  {
    super.scrollWheel(with: event)
        
    // save the cursor pos
    let cursorPos = selectedRange()

    // find the para of the visble text
    guard let lm = self.layoutManager else {return}
    guard let tc = self.textContainer else {return}
    let visibleRange = lm.glyphRange(forBoundingRect: self.visibleRect,
                                     in: tc)

    let r = NSMakeRange(visibleRange.location + 100, 0)
    self.setSelectedRange(r)

    //sync with preview if user prefer
    VC.syncPreviewWithEditor(self)

    // move cursor back
    self.setSelectedRange(cursorPos)
  }
  
  func setup(_ vc: ViewController)
  {
    VC = vc
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
    
    highlightedCS.highlightr.theme.codeFont = NSFont(name: "PT Mono", size: 16)
    highlightedCS.highlightr.theme.boldCodeFont = NSFont(name: "PT Mono", size: 16)
    highlightedCS.highlightr.theme.italicCodeFont = NSFont(name: "PT Mono", size: 16)
    
    //turn off stupid substitution
    if self.isAutomaticQuoteSubstitutionEnabled
    {
      self.toggleAutomaticQuoteSubstitution(self)
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
    let md = self.string
    DispatchQueue.global(qos: .background).async
    {
       if let ol = Markdown.herderOutline(md)
       {
         DispatchQueue.main.async
         {
           let selectedTitle = self.VC.outlineSelector.selectedItem?.title
           
           self.VC.outlineSelector.removeAllItems()
           self.VC.outlineSelector.addItems(withTitles: ol)
          
           if let title = selectedTitle
           {
             self.VC.outlineSelector.selectItem(withTitle: title)
           }
           else
           {
            self.VC.outlineSelector.selectItem(at: 0)
           }
         }
       }
       else
       {
         Log.info("updating outline did not update, because outline is empty")
       }
    }
  }
}// MarkDownEditorView



