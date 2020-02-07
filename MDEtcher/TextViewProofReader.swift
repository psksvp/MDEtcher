//
//  ProofReaderAV.swift
//  MDEtcher
//
//  Created by psksvp on 25/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import AppKit
import AVFoundation
import CommonSwift

//class TextViewProofReaderAV: NSObject, AVSpeechSynthesizerDelegate
//{
//  private var synthesizer = AVSpeechSynthesizer()
//  private let textView: NSTextView
//  private var text:String? = nil
//
//  init(forTextView tv: NSTextView)
//  {
//    self.textView = tv
//    super.init()
//    self.synthesizer.delegate = self
//  }
//
//  func changeVoice()
//  {
//    for v in AVSpeechSynthesisVoice.speechVoices()
//    {
//      print("\(v.name) \(v.identifier) \(v.quality == .enhanced ? "good" : "bad") ")
//    }
//  }
//
//  func startAtCursor()
//  {
//    text = textView.textBlockAtCursor()
//    start()
//  }
//
//  func start()
//  {
//    if self.synthesizer.isSpeaking
//    {
//      Log.warn("ProofReader is speaking, will not start another one")
//    }
//
//    if let s = text
//    {
//      let u = AVSpeechUtterance(string: s)
//      u.rate = 0.35
//      u.pitchMultiplier = 0.25
//      u.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-US_compact")
//      self.synthesizer.speak(u)
//    }
//    else
//    {
//      Log.error("ProofReader did not start, text is nil")
//    }
//
//  }
//
//  func stop()
//  {
//    if self.synthesizer.isSpeaking
//    {
//      self.synthesizer.stopSpeaking(at: .word)
//    }
//  }
//
//
//  // delegate
//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
//                         willSpeakRangeOfSpeechString characterRange: NSRange,
//                         utterance: AVSpeechUtterance)
//  {
//    DispatchQueue.main.async  // this delegate is called from a thread, so put on the main thread for GUI stuff
//    {
//      if let r = self.textView.string.intIndex(of: utterance.speechString)
//      {
//        let m = NSMakeRange(r + characterRange.location, characterRange.length)
//        self.textView.setSelectedRange(m)
//      }
//    }
//  }
//
//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
//                         didFinish utterance: AVSpeechUtterance)
//  {
//    self.text = nil
//  }
//
//  // handle actions
//  func handleAction(_ s: String)
//  {
//    switch s.lowercased()
//    {
//      case "start" : self.startAtCursor()
//      case "stop"  : self.stop()
//      case "pause" : Log.info("ProofReaderAV.pause() is dummy")
//      case "voice" : self.changeVoice()
//      default      : Log.error("ProofReaderAV.handleAction don't know action \(s)")
//    }
//  }
//}


//////////////////////////////
func voiceInfoOfNSSpeechSynthesizer() -> [String]
{
  var names = [String]()
  for v in NSSpeechSynthesizer.availableVoices
  {
    let attributes = NSSpeechSynthesizer.attributes(forVoice: v)
    let voiceName = attributes[.name]! as? String
    //let language = attributes[.localeIdentifier]! as? String
    //let gender = attributes[.gender]! as? String
  
    //let vs = "\(voiceName!)-\(language!)"
    names.append(voiceName!)
  }
  return names
}

func newSpeechSynthesizer(withVoice s: String) -> NSSpeechSynthesizer
{
  for v in NSSpeechSynthesizer.availableVoices
  {
    let voiceName = NSSpeechSynthesizer.attributes(forVoice: v)[.name]! as? String
    if voiceName == s
    {
      return NSSpeechSynthesizer(voice: v)!
    }
  }
  
  Log.warn("newSpeechSynthesizer is returning a NSSpeechSynthesizer with default voice")
  return NSSpeechSynthesizer(voice: nil)!
}

func newVoice(withName s: String) -> NSSpeechSynthesizer.VoiceName?
{
  for v in NSSpeechSynthesizer.availableVoices
  {
    let voiceName = NSSpeechSynthesizer.attributes(forVoice: v)[.name]! as? String
    if voiceName == s
    {
      return v
    }
  }
  
  Log.warn("newVoice is returning nil")
  return nil
}

/////////////////////////////////////////////////////////////////////////////////////////////
class TextViewProofReader: NSObject, NSSpeechSynthesizerDelegate
{
  private var synthesizer = newSpeechSynthesizer(withVoice: "Samantha")
  private let textView: NSTextView
  private var writingToFile = false
  
  var text:String? = nil
  
  init(forTextView tv: NSTextView)
  {
    self.textView = tv
    super.init()
  }
  
  func changeVoice()
  {
    VoicesSelectorWindowController.shared.show()
  }
  
  func startAtCursor()
  {
    text = textView.textBlockAtCursor()
    start()
  }
  
  func start(toURL url: URL? = nil)
  {
    if self.synthesizer.isSpeaking
    {
      Log.warn("ProofReader is speaking, will not start another one")
    }
    
    if let s = text
    {
      self.synthesizer.delegate = self
      if let voice = newVoice(withName: Preference.proofReadVoiceName)
      {
        Log.info("ProofReader is going to read with voice \(voice)")
        self.synthesizer.setVoice(voice)
      }
      self.synthesizer.rate = Preference.proofReadVoiceRate
      
      if let fileURL = url
      {
        writingToFile = true
        self.synthesizer.startSpeaking(s, to: fileURL)
      }
      else
      {
        writingToFile = false
        self.synthesizer.startSpeaking(s)
      }
    }
    else
    {
      Log.error("ProofReader did not start, text is nil")
    }
    
  }
  
  func stop()
  {
    if self.synthesizer.isSpeaking
    {
      self.synthesizer.stopSpeaking()
    }
  }
  
  func pause()
  {
    if self.synthesizer.isSpeaking
    {
      self.synthesizer.pauseSpeaking(at: .wordBoundary)
    }
  }
  
  
  // delegate
  func speechSynthesizer(_ sender: NSSpeechSynthesizer,
                         willSpeakWord characterRange: NSRange,
                         of string: String)
  {
    
    func rangeOfWordTTSWillSpeak() -> NSRange?
    {
      // var *string* contains a block of text inside textView.string
      // *characterRange* contains the range of the word which about to be spoken in
      // *string*
      
      // first the range of block of text (var string) in textview
    
      //let text = self.textView.textStorage?.string
  
      guard let r = self.textView.string.range(of: string) else
      {
        Log.warn("rangeOfWordTTSWillSpeak could not find string block in textView")
        return nil
      }
      
      let nsr = NSRange(r, in: self.textView.string)
      return NSMakeRange(nsr.location + characterRange.location, characterRange.length)
    }
    
    
    if self.writingToFile,
       let word = string.substring(with: characterRange)
    {
      WorkPrograssWindowController.shared.message.append("\(word)")
    }
    else
    {
      guard let r = rangeOfWordTTSWillSpeak() else {return}
      self.textView.setSelectedRange(r)
    }
  }
  
  func speechSynthesizer(_ sender: NSSpeechSynthesizer,
                         didFinishSpeaking finishedSpeaking: Bool)
  {
    self.text = nil
    if writingToFile
    {
      WorkPrograssWindowController.shared.hide()
    }
  }
  
  func speechSynthesizer(_ sender: NSSpeechSynthesizer, didEncounterSyncMessage message: String)
  {
    Log.warn("speechSynthesizer Sync Message : \(message)")
  }
  
  func speechSynthesizer(_ sender: NSSpeechSynthesizer, didEncounterErrorAt characterIndex: Int, of string: String, message: String)
  {
    Log.warn("speechSynthesizer error at char \(characterIndex), message: \(message)")
  }
  
  // handle actions
  func handleAction(_ s: String)
  {
    switch s.lowercased()
    {
      case "start" : self.startAtCursor()
      case "stop"  : self.stop()
      case "pause" : self.pause()
      case "voice" : self.changeVoice()
      default      : Log.error("ProofReader.handleAction don't know action \(s)")
    }
  }
}




