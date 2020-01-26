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
  class func herderOutline(_ md: String) -> [String]?
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
    let result = reader.headers.joined(separator: "|") + "\n" +
                 String(repeating: "---|", count: reader.headers.count) + "\n" +
                 reader.rows.map{$0.joined(separator: "|")}.joined(separator: "\n")
    return result
  }
  
  
  // filters
  /////////////////////
  
  class func csvBlocks2Tables(_ md: String) -> String
  {
    var result = md

    let pattern = #"(?s)~~~\s*csvtable\s*(.*?)~~~"#
    let regex = try? NSRegularExpression(pattern: pattern, options:[])
    for (_, csvBlock) in md.findAndLift(string: pattern, options: [.regularExpression])
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
  
  
  class func dot2Image(_ md: String) -> String
  {
    return md
  }
  
}
