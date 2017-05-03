//
//  Constants.swift
//  whiteTiger
//
//  Created by Dongjie Zhang on 3/27/17.
//  Copyright © 2017 Zachary. All rights reserved.
//

import Foundation


struct Constants {
    struct BLE {
        static let DEVICE_NAME = "BH_70C2"
        static let SERVICE_UUID = "00001523-1212-EFDE-1523-785FEABCD123"
        static let PPG_CHARACTERISTIC_UUID = "00001524-1212-EFDE-1523-785FEABCD123"
        static let CTRL_CHARACTERISTIC_UUID = "00001525-1212-EFDE-1523-785FEABCD123"
        static let TEMP_CHARACTERISTIC_UUID = "00001526-1212-EFDE-1523-785FEABCD123"
    }
    
    struct NOTIFICATION {
        static let DID_RECEIVE_TEMP = "BLEConnectionDidReceiveTempData"
        static let DID_RECEIVE_PPG = "BLEConnectionDidReceivePPGData"
    }
    
}
