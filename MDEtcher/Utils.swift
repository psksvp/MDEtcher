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








