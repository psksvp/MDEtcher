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
    if let (output, err) = OS.spawn([Resource.pandocExecutable] + args, Markdown.runfilters(md))
    {
      Log.warn("pandoc stderr : \(err)")
      return output
    }
    else
    {
      return nil
    }
  }
  // refactor me
  @discardableResult class func runWithProgressShowed(_ md: String, _ args: [String]) -> String?
  {
    DispatchQueue.main.async
    {
      WorkPrograssWindowController.shared.message = args.joined(separator: " ")
    }
    
    if let (output, err) = OS.spawn([Resource.pandocExecutable] + args, Markdown.runfilters(md))
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
    
    let scrollPassEnd = previewing ? ["--include-after-body=\(Resource.newLinesBlockPath!)"] : []
    let mermaid = true ? ["--include-in-header=\(Resource.mermaidHTMLPath!)"] : []
    
    let args = ["--css=\(cssPath)",
                "--from=markdown_strict+tex_math_dollars+footnotes+subscript+superscript+table_captions",
                "--to=html5",
                "--self-contained",
                "-s",
                "--metadata", "pagetitle=\"MDPreview\"",
                "--mathjax=\(Resource.mathJax)"] + scrollPassEnd + mermaid
  
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
