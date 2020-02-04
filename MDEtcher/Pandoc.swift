//
//  Pandoc.swift
//  MDEtcher
//
//  Created by psksvp on 7/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import AppKit
import CommonSwift

class Pandoc
{
  @discardableResult class func run(_ md: String, _ args: [String]) -> String?
  {
    let mdf1 = Markdown.csvBlocks2Tables(md)
    
    if let (output, err) = OS.spawn([Resource.pandocExecutable] + args, mdf1)
    {
      Log.warn("pandoc stderr : \(err)")
      return output
    }
    else
    {
      return nil
    }
  }
  
  @discardableResult class func runWithProgressShowed(_ md: String, _ args: [String]) -> String?
  {
    let mdf1 = Markdown.csvBlocks2Tables(md)
    
    DispatchQueue.main.async
    {
      WorkPrograssWindowController.shared.message = args.joined(separator: " ")
    }
    
    if let (output, err) = OS.spawn([Resource.pandocExecutable] + args, mdf1)
    {
      DispatchQueue.main.async
      {
        if false == err.isEmpty
        {
          Log.warn("pandoc stderr : \(err)")
          WorkPrograssWindowController.shared.enableDoneButton()
          WorkPrograssWindowController.shared.message = "Pandoc Error:\n \(err)"
        }
        else
        {
          WorkPrograssWindowController.shared.hide()
        }
      }
      return output
    }
    else
    {
      return nil
    }
  }
  
  class func toHTML(markdown: String,
                    css cssName:String,
                    previewing: Bool = true) -> String?
  {
    guard let cssPath = Resource.css(cssName) else
    {
      Log.error("\(cssName) cannot be found")
      return nil
    }
    
    let args = ["--css=\(cssPath)",
                "--to=html5",
                "--self-contained",
                "-s",
                "--metadata", "pagetitle=\"MDPreview\"",
                "--mathjax=\(Resource.mathJax)"]
  
    if previewing
    {
      // allow scroll pass end
      guard let htmlString = run(markdown, args) else {return nil}
      let brs = String(repeating: "<br>", count: 30)
      return htmlString.replacingOccurrences(of: "</body>\n</html>", with: "\(brs)</body></html>")
    }
    else
    {
      return run(markdown, args)
    }
  }
  
  class func toHTML(markdown: String) -> String?
  {
    let args = ["--to=html5", "--mathjax=\(Resource.mathJax)"]
    return run(markdown, args)
  }
  
  class func toText(markdown: String) -> String?
  {
    let args = ["--to=html5"]
    return run(markdown, args)
  }
  
  class func write(_ md: String, toHTMLFileAtPath path:String, usingCSS css: String) -> Void
  {
    if let html = self.toHTML(markdown: md, css: css, previewing: false)
    {
      FS.writeText(inString: html, toPath: path)
    }
    else
    {
      Log.error("Pandoc fail to write HTML to path \(path)")
    }
  }
  
  class func write(_ md: String, toPDF pdfOutputPath: String) -> Void
  {
    guard let xelatex = Resource.xelatexPath else
    {
      Log.warn("users did not select path to xelatex")
      return
    }

    let args = ["--top-level-division=chapter",
                "--toc",
                "--pdf-engine=\(xelatex)",
                "-V", "linkcolor:blue",
                //"-V", "geometry:a4paper",
                "-o", pdfOutputPath]
    Log.info("going to run pandoc \(args.joined(separator:" "))")
    runWithProgressShowed(md, args)

  }
}
