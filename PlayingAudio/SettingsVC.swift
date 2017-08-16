//
//  SettingsVC.swift
//  PlayingAudio
//
//  Created by Karim El Sheikh on 8/11/17.
//  Copyright © 2017 playing. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController {
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var autoplaySwitch: UISwitch!
    @IBOutlet weak var autoplayAllSwitch: UISwitch!
    
    @IBAction func autoplaySwitchChange(_ sender: Any) {
        defaults.set(self.autoplaySwitch.isOn, forKey: "savedSwitchSettingDefault")
        defaults.synchronize()
        
    }
    
    @IBAction func autoplayAllSwitchChange(_ sender: Any) {
        defaults.set(self.autoplayAllSwitch.isOn, forKey: "savedAllAutoplaySwitchSettingDefault")
        defaults.synchronize()
    }
    
    @IBAction func doneBtn(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated:true)
        self.autoplaySwitch.isOn = self.defaults.bool(forKey: "savedSwitchSettingDefault")
        self.autoplayAllSwitch.isOn = self.defaults.bool(forKey: "savedAllAutoplaySwitchSettingDefault")
    }
}
