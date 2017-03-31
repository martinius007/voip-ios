//
//  ViewController.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var number: String?
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var myNumberLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.number = ""
        self.numberLabel.text = ""
        self.myNumberLabel.text = ""
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func tapNumber(_ sender: UIButton) {
        if let title = sender.currentTitle {
            if let number = self.number {
                self.number = number + title
            } else {
                self.number = title
            }
            updateNumber()
        }
    }

    @IBAction func tapCall(_ sender: UIButton) {
    }
    
    @IBAction func tapClear(_ sender: UIButton) {
        if let number = self.number, !number.isEmpty {
            let endIndex = number.index(number.endIndex, offsetBy: -1)
            self.number = number.substring(to: endIndex)
            updateNumber()
        }
    }
    
    func updateNumber() {
        self.numberLabel.text = self.number
    }
    
}

