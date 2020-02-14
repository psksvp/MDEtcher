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

func fileSelectorDialog(_ message: String, userSelected: @escaping (_ path: String) -> Void) -> Void
{
  let openPanel = NSOpenPanel()
  openPanel.title = message
  openPanel.message = message
  openPanel.allowsMultipleSelection = false
  openPanel.canChooseDirectories = false
  openPanel.canCreateDirectories = false
  openPanel.canChooseFiles = true
  if .OK == openPanel.runModal()
  {
    userSelected(openPanel.url!.path)
  }
}

func directoryPathOfFileURL(_ url: URL) -> String
{
  return url.deletingLastPathComponent().path
}

func directoryURL(ofFileURL url: URL) -> URL
{
  return url.deletingLastPathComponent()
}


func fileExists(_ name: String, inDirectory dir: URL) -> Bool
{
  do
  {
    let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
    let enumerator = FileManager.default.enumerator(at: dir,
                            includingPropertiesForKeys: resourceKeys,
                                              options: [.skipsHiddenFiles])!
  
    for case let fileURL as URL in enumerator
    {
      let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
      //print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
      if false == resourceValues.isDirectory! &&
         fileURL.lastPathComponent == name
      {
        return true
      }
    }
  }
  catch
  {
    Log.error(error.localizedDescription)
  }
  
  return false
}
