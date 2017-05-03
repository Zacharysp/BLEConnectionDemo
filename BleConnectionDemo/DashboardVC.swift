//
//  DashboardVC.swift
//  whiteTiger
//
//  Created by Dongjie Zhang on 3/27/17.
//  Copyright © 2017 Zachary. All rights reserved.
//

import UIKit
import CoreBluetooth

class DashboardVC: UIViewController {
    
    var peripheral : CBPeripheral?
    
    var startTimer: Timer?
    var startTimerRepeatCount = 19
    
    var fingerTemp = 0
    var envTemp = 0
    var envHumidity = 0
    
    var ppgDataProcessor: DataProcessor?

    @IBOutlet weak var startBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //navigate from bluetooth page, already have a connected peripheral
        if peripheral != nil {
            BluetoothManager.sharedInstance.connect(peripheral: peripheral!)
        }else {
            //dont have a connected peripheral, need to scan by name
            BluetoothManager.sharedInstance.scanWithDeviceName()
        }
        renewData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //add notification observer
        ObserveNotification()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //stop device if it is still sending data
        sendStopToDevice()
        //disconnect device
        BluetoothManager.sharedInstance.disconnect()
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func startBtnPressed(_ sender: UIButton) {
        if startTimer == nil {
            //restart data
            renewData()
            //send start to device
            BluetoothManager.sharedInstance.writePeripheral(num: 1)
            //set counting down timer
            startTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {
                timer in
                guard self.startTimerRepeatCount != 0  else {
                    self.sendStopToDevice()
                    return
                }
                self.setStartButtonTitle(title: String(self.startTimerRepeatCount))
                self.startTimerRepeatCount = self.startTimerRepeatCount - 1
            })
        }else {
            //press again on button to stop
            sendStopToDevice()
        }
    }
    
    //stop timer, and send stop to device
    func sendStopToDevice(){
        guard startTimer != nil  else {
            return
        }
        BluetoothManager.sharedInstance.writePeripheral(num: 0)
        startTimer?.invalidate()
        startTimer = nil
        startTimerRepeatCount = 20
        setStartButtonTitle(title: "Start")
        
        print(fingerTemp, envTemp, envHumidity)
        print(ppgDataProcessor?.ppgArray ?? "null")
    }
    
    
    func setStartButtonTitle(title: String){
        DispatchQueue.main.async {
            self.startBtn.setTitle(title, for: .normal)
        }
    }
    
    
    func renewData(){
        //init value with -99, the coming value will never be -99
        fingerTemp = -99
        envTemp = -99
        envHumidity = -99
        ppgDataProcessor = DataProcessor()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Notification 
    func ObserveNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(DashboardVC.readTempData(_:)), name: Notification.Name(Constants.NOTIFICATION.DID_RECEIVE_TEMP), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DashboardVC.readPPGData(_:)), name: Notification.Name(Constants.NOTIFICATION.DID_RECEIVE_PPG), object: nil)
    }
    
    func readTempData(_ notification: NSNotification){
        guard notification.userInfo != nil else {
            return
        }
        if let value = notification.userInfo![0] as? UInt8 {
            fingerTemp = getAverage(average: fingerTemp, newValue: Int(Int8(bitPattern: value)))
        }
        if let value = notification.userInfo![1] as? UInt8 {
            envTemp = getAverage(average: envTemp, newValue: Int(Int8(bitPattern: value)))
        }
        if let value = notification.userInfo![2] as? UInt8 {
            envHumidity = getAverage(average: envHumidity, newValue: Int(value))
        }
    }
    
    fileprivate func getAverage(average: Int, newValue: Int) -> Int{
        if average == -99 {
            return newValue
        }else {
            return (average + newValue) / 2
        }
    }
    
    func readPPGData(_ notification: NSNotification){
        guard notification.userInfo != nil else {
            return
        }
        if let data = notification.userInfo![0] as? Data {
            ppgDataProcessor?.processNewSegment(segData: data)
        }
    }
}
