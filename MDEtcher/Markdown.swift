//
//  Markdown.swift
//  MDEtcher
//
//  Created by psksvp on 12/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import CommonSwift


class Markdown
{
  class func headerOutline(_ md: String) -> [String]?
  {
    func headers() -> [Substring]
    {
      md.split(separator: "\n").filter { isHeader(String($0)) }
    }
    
    func isHeader(_ line: String) -> Bool
    {
      for h in ["######", "#####", "####", "###", "##", "#"]
      {
        if line.hasPrefix(h)
        {
          return true
        }
      }
      
      return false
    }
    
    func removeHash(_ s: String) -> String
    {
      func hash2space(_ c: Character) -> Character
      {
        return c == "#" ? " " : c
      }
      
      let m = s.map
      {
        hash2space($0)
      }
      
      return String(m)
    }
    
    let ol = headers().map
    {
      removeHash(String($0))
    }
    
    return ol.count > 0 ? ol : nil
  }
  
  class func csv2MdTable(_ csv: String) -> String?
  {
    let reader = CSVReader(with: csv)

    let result = """
    \(reader.headers.joined(separator: "|"))
    \(String(repeating: "---|", count: reader.headers.count))
    \(reader.rows.map{$0.joined(separator: "|")}.joined(separator: "\n"))
    """
    return result
  }
  
  
  // filters
  
  class func runfilters(_ md: String) -> String
  {
    var mdf = filterAsciiMath(md)
    if mdf.contains("csvtable")
    {
      mdf = Markdown.filterCSV(mdf)
    }
    
    if mdf.contains("mermaid")
    {
      mdf = Markdown.filterMermaid(mdf)
    }
    
    return mdf
  }
  
  /////////////////////
  //// REFACTOR HERE
  class func filterCSV(_ md: String) -> String
  {
    var result = md

    let pattern = #"(?s)~~~\s*csvtable\s*(.*?)~~~"#
    let regex = try? NSRegularExpression(pattern: pattern, options:[])
    for (_, csvBlock) in md.liftRegexPattern(pattern)
    {
      if let match = regex?.firstMatch(in: csvBlock,
                                       options: [],
                                       range: NSRange(csvBlock.startIndex..<csvBlock.endIndex, in: csvBlock)),
         let range = Range(match.range(at: 1), in: csvBlock),
         let table = csv2MdTable(String(csvBlock[range]))
      {
        result = result.replacingOccurrences(of: csvBlock, with: table)
      }
    }
    
    return result
  }
  
  
  class func filterMermaid(_ md: String) -> String
  {
    func toMermaidDiv(_ s: String) -> String
    {
      return """
      <div class="mermaid">
      \(s)
      </div>
      """
    }
    
    var result = md

    let pattern = #"(?s)~~~\s*mermaid\s*(.*?)~~~"#
    let regex = try? NSRegularExpression(pattern: pattern, options:[])
    for (_, mmBlock) in md.liftRegexPattern(pattern)
    {
      if let match = regex?.firstMatch(in: mmBlock,
                                       options: [],
                                       range: NSRange(mmBlock.startIndex..<mmBlock.endIndex, in: mmBlock)),
         let range = Range(match.range(at: 1), in: mmBlock)
      {
        let mermaidDiv = toMermaidDiv(String(mmBlock[range]))
        result = result.replacingOccurrences(of: mmBlock, with: mermaidDiv)
      }
    }
    
    return result
  }
  
  
  /*
   
   <`(.*?)`>
   */
  
  class func filterAsciiMath(_ md: String) -> String
  {
    var result = md

    let pattern = #"<`(.*?)`>"#
    let regex = try? NSRegularExpression(pattern: pattern, options:[])
    for (_, mmBlock) in md.liftRegexPattern(pattern)
    {
      if let match = regex?.firstMatch(in: mmBlock,
                                       options: [],
                                       range: NSRange(mmBlock.startIndex..<mmBlock.endIndex, in: mmBlock)),
         let range = Range(match.range(at: 1), in: mmBlock)
      {
        let backTick = "`` `\(String(mmBlock[range]).trim())` ``"
        result = result.replacingOccurrences(of: mmBlock, with: backTick)
      }
    }
    
    return result
  }
  
}
