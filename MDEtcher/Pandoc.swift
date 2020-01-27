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
  private var path:String = ""
  
  var busyImage: NSImage?
  {
    get
    {
      return NSImage(contentsOfFile: "\(path)/busy.gif")
    }
  }
  
  public init()
  {
    if let rsc = Bundle.main.resourceURL
    {
      path = "\(rsc.path)/pandoc"
    }
  }
  
  @discardableResult public func run(_ md: String, _ args: [String]) -> String?
  {
    let mdf1 = Markdown.csvBlocks2Tables(md)
    
    if let (output, err) = OS.spawn(["\(path)/pandoc"] + args, mdf1)
    {
      Log.warn("pandoc stderr : \(err)")
      return output
    }
    else
    {
      return nil
    }
  }
  
  public func toHTML(markdown: String, css:String) -> String?
  {
    let args = ["--css=\(path)/css/\(css)",
                "--to=html5",
                "--self-contained",
                "-s",
                "--metadata", "pagetitle=\"MDPreview\"",
                "--mathjax=\(path)/MathJax/MathJax.js"]
    
    return run(markdown, args)
  }
  
  public func toHTML(markdown: String) -> String?
  {
    let args = ["--to=html5", "--mathjax=\(path)/MathJax/MathJax.js"]
    return run(markdown, args)
  }
  
  public func write(_ md: String, toHTMLFileAtPath path:String, usingCSS css: String) -> Void
  {
    if let html = self.toHTML(markdown: md, css: css)
    {
      FS.writeText(inString: html, toPath: path)
    }
    else
    {
      Log.error("Pandoc fail to write HTML to path \(path)")
    }
  }
  
  public func write(_ md: String, toPDF pdfOutputPath: String) -> Void
  {
    let args = ["--top-level-division=chapter",
                "--toc",
                "--pdf-engine=/Library/TeX/texbin/xelatex",
                "-V", "linkcolor:blue",
                "-V", "geometry:a4paper",
                "-o", pdfOutputPath]
    
    run(md, args)
  }
}
