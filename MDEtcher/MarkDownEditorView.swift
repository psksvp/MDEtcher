//
//  MarkDownEditorView.swift
//  MDEtcher
//
//  Created by psksvp on 9/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Cocoa
import CommonSwift


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
class MarkDownEditorView: NSTextView
{
  var viewController: ViewController!
  
  private var _proofReader: TextViewProofReader? = nil
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
  
//  private var _proofReader: TextViewProofReaderAV? = nil
//  var proofReader: TextViewProofReaderAV
//  {
//    get
//    {
//      if let p = _proofReader
//      {
//        return p
//      }
//      else
//      {
//        _proofReader = TextViewProofReaderAV(forTextView: self)
//        return _proofReader!
//      }
//
//    }
//  }
  
  private let speechSyn: NSSpeechSynthesizer = NSSpeechSynthesizer(voice: nil)!
  
  override func mouseDown(with event: NSEvent)
  {
    super.mouseDown(with: event)
    proofReader.stop() // if it is running
    viewController.syncWithEditor(self)
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
    viewController.syncWithEditor(self)

    // move cursor back
    self.setSelectedRange(cursorPos)
  }
}



