//
//  ConnectionVC.swift
//  whiteTiger
//
//  Created by Dongjie Zhang on 3/27/17.
//  Copyright © 2017 Zachary. All rights reserved.
//

import UIKit

class ConnectionVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = BluetoothManager.sharedInstance
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
