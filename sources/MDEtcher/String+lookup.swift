//
//  NSString+lookup.swift
//  MDEtcher
//
//  Created by psksvp on 3/2/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation

// Recode by looking at ObjC code from Macdown at url below
// https://github.com/MacDownApp/macdown/blob/master/MacDown/Code/Extension/NSString%2BLookup.m
// .......
extension NSString
{
  func locationOfFirstNewlineBefore(_ loc: Int) -> Int
  {
    let location = loc > self.length ? self.length : loc
    
    var start = 0
    self.getLineStart(&start,
                      end: nil,
                      contentsEnd: nil,
                      for: NSMakeRange(location, 0))
    
    return start - 1
  }
  
  func locationOfFirstNewLineAfter(_ loc: Int) -> Int
  {
    let location = (loc + 1) > self.length ? self.length : loc
    var end = 0
    self.getLineStart(nil,
                      end: nil,
                      contentsEnd: &end,
                      for: NSMakeRange(location, 0))
    return end
  }
  
  func locationOfFirstNonWhitespaceCharacterInLineBefore(_ loc: Int) -> Int
  {
    var p = self.locationOfFirstNewlineBefore(loc) + 1
    let location = loc > self.length ? self.length : loc
    while let c = UnicodeScalar(self.character(at: p)),
          (p < location && CharacterSet.whitespaces.contains(c))
    {
      p = p + 1
    }
    return p
  }
  
  func matchesForPattern(_ p: NSString) -> [NSTextCheckingResult]
  {
    let e = try! NSRegularExpression(pattern: p as String,
                                     options: NSRegularExpression.Options(rawValue: 0))
    return e.matches(in: self as String,
                     options: [],
                     range: NSMakeRange(0, self.length))
  }
}
