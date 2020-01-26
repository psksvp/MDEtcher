//
//  VoicesSelectorWindowController.swift
//  MDEtcher
//
//  Created by psksvp on 25/1/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Cocoa

class VoicesSelectorWindowController: NSWindowController
{
  private static var _one:VoicesSelectorWindowController? = nil
  static var shared:VoicesSelectorWindowController
  {
    get
    {
      if let _ = _one
      {
        return _one!
      }
      else
      {
        _one = VoicesSelectorWindowController()
        return _one!
      }
    }
  }
  
  
  @IBOutlet weak var voiceRateText: NSTextField!
  @IBOutlet weak var voiceRateSlider: NSSlider!
  @IBOutlet weak var voicesComboBox: NSComboBox!
  
  override var windowNibName: NSNib.Name?
  {
    return "VoicesSelectorWindowController"
  }
  
  override func windowDidLoad()
  {
    super.windowDidLoad()
    
    voicesComboBox.addItems(withObjectValues: voiceInfoOfNSSpeechSynthesizer())
    voicesComboBox.selectItem(withObjectValue: Preference.proofReadVoiceName)
    voiceRateSlider.floatValue = Preference.proofReadVoiceRate
    voiceRateText.stringValue = "Rate:\(Preference.proofReadVoiceRate)"
  }
  
  @IBAction func donePush(_ sender: Any)
  {
    self.window?.orderOut(self)
  }
  
  
  @IBAction func voiceSelected(_ sender: NSComboBox)
  {
    Preference.proofReadVoiceName = sender.stringValue
  }
  
  
  @IBAction func rateValueChange(_ sender: NSSlider)
  {
    Preference.proofReadVoiceRate = Float(sender.intValue)
    voiceRateText.stringValue = "Rate:\(sender.intValue)"
  }
  
  func show()
  {
    self.window!.orderFront(self)
  }
}
