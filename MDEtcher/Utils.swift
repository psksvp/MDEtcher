//
//  GUI.swift
//  MDEtcher
//
//  Created by psksvp on 13/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import Cocoa
import AppKit
import WebKit
import CommonSwift


func putCheckmark(item: NSMenuItem, inMenu m: NSMenu)
{
  putCheckmark(title: item.title, inMenu: m)
}

func putCheckmark(title: String, inMenu m: NSMenu)
{
  for i in m.items
  {
    i.state = i.title == title ? .on : .off
  }
}

func readDefault(forkey key:String, notFoundReturn:  String) -> String
{
  switch UserDefaults.standard.string(forKey: key)
  {
    case .some(let s) : return s
    default           : return notFoundReturn
  }
}

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


func paragraphAtCursorIn(textView tv:NSTextView) -> String?
{  
  return paragraphAtRange(tv.selectedRange(), inTextView: tv)
}

func paragraphAtRange(_ r: NSRange, inTextView tv:NSTextView) -> String?
{
  guard let textStorage = tv.textStorage else {return nil}
  let text = textStorage.string
  guard let f = Range(r, in: text) else {return nil}
  let pr = text.paragraphRange(for: f)
  if tv.string[pr].trim().count > 0
  {
    return String(tv.string[pr]).trim()
  }
  else
  {
    return nil
  }
}


