//
//  Data+ImageFileFormat.swift
//  MDEtcher
//
//  Created by psksvp on 17/2/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation

class ImageFile
{
  private let data: Data
  let format: Format?
  
  struct Format
  {
    var name: String
    var signature: [UInt8]
  }
  
  private static let formats = [Format(name: "PNG", signature: [137, 80, 78, 71, 13, 10, 26, 10]),
                                Format(name: "JPEG", signature: [0xff, 0xd8, 0xff]),
                                Format(name: "GIF", signature: [47, 49, 46, 38])]
                    
  init?(fromURL url: URL)
  {
    do
    {
      data = try Data(contentsOf: url)
      for f in ImageFile.formats
      {
        if let r = data.range(of: Data(bytes: f.signature, count: f.signature.count)),
           r.startIndex == data.startIndex // must be at start of block
        {
          format = f
          return
        }
      }
      return nil
    }
    catch
    {
      return nil
    }
  }
  
  func write(toPath p: String) -> Bool
  {
    guard let f = format else {return false}

    let filePath = "\(p).\(f.name)"
    do
    {
      try data.write(to: URL(fileURLWithPath: filePath))
      return true
    }
    catch
    {
      return false
    }
  }
}

