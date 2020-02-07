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
      if false == err.trim().isEmpty
      {
        DispatchQueue.main.async
        {
          WorkPrograssWindowController.shared.show("Pandoc Error")
          WorkPrograssWindowController.shared.message = err
          WorkPrograssWindowController.shared.enableDoneButton()
        }
      }
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
                    filesResourcePath rp: String? = nil,
                    previewing: Bool = true) -> String?
  {
    guard let cssPath = Resource.css(cssName) else
    {
      Log.error("\(cssName) cannot be found")
      return nil
    }
    

    let scrollPassEnd = previewing ? ["--include-after-body=\(Resource.newLinesBlockPath!)"] : []
    
    let mermaid = markdown.range(of: #"~~~\s*mermaid"#,
                            options: .regularExpression) != nil ? ["--include-in-header=\(Resource.mermaidHTMLPath!)"] : []
    
    let asciiMath = markdown.range(of: #"<`(.*?)`>"#,
                              options: .regularExpression) != nil ? ["--include-in-header=\(Resource.asciiMathHTMLPath!)"] : []
    
    let rscPath = rp == nil ? [] : ["--resource-path=.:\(rp!)"]
    
    let args = ["--css=\(cssPath)",
                "--from=markdown_strict+tex_math_dollars+footnotes+subscript+superscript+table_captions+grid_tables+multiline_tables+pipe_tables+simple_tables+strikeout+backtick_code_blocks+auto_identifiers+citations+example_lists+fancy_lists+header_attributes+yaml_metadata_block",
                "--to=html5",
                "--self-contained",
                "-s",
                "--metadata", "pagetitle=\"MDPreview\"",
                "--mathjax=\(Resource.mathJax)"] + scrollPassEnd + mermaid + asciiMath + rscPath
    print(args)
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
