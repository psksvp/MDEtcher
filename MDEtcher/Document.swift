//
//  Document.swift
//  MDEtcher
//
//  Created by psksvp on 6/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Cocoa
import CommonSwift

class Document: NSDocument 
{
  private var textView: NSTextView!
  private var viewController: ViewController!
  private var textReadBuffer = ""
  
  override init()
  {
    super.init()
  }

  override class var autosavesInPlace: Bool
  {
    return true
  }

  override func makeWindowControllers()
  {
    // Returns the Storyboard that contains your Document window.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
    self.addWindowController(windowController)
    
    if let vc = windowController.contentViewController as? ViewController
    {
      viewController = vc
      if let tv = vc.editorView
      {
        tv.string = textReadBuffer
        textView = tv
        viewController.updateOutline(md: textReadBuffer)
      }
      else
      {
        Log.warn("did not get ref to textView")
      }
    }
    else
    {
      Log.warn("did not get ref to ViewController")
    }
  }

  override func data(ofType typeName: String) throws -> Data
  {
    viewController.updateOutline(md: textView.string)
    switch textView.string.data(using: .utf8)
    {
      case .some(let d) : return d
                default : throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
  }

  override func read(from data: Data, ofType typeName: String) throws
  {
    if let text = String(data: data, encoding: .utf8)
    {
      textReadBuffer = text
    }
    else
    {
      throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
  } //read
}




