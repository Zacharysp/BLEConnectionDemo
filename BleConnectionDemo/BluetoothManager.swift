//
//  BluetoothManager.swift
//  whiteTiger
//
//  Created by Dongjie Zhang on 3/27/17.
//  Copyright © 2017 Zachary. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate{
    func didDiscover(peripheral: CBPeripheral)
    func centralReady()
}

class BluetoothManager: NSObject {
    static let sharedInstance = BluetoothManager()
    public var delegate:BluetoothManagerDelegate?
    
    //service UUID
    fileprivate let serviceId = CBUUID(string: Constants.BLE.SERVICE_UUID)
    //Characteristic UUID
    fileprivate let PPGCharacteristicId = CBUUID(string: Constants.BLE.PPG_CHARACTERISTIC_UUID)
    fileprivate let CtrlCharacteristicId = CBUUID(string: Constants.BLE.CTRL_CHARACTERISTIC_UUID)
    fileprivate let TempCharacteristicId = CBUUID(string: Constants.BLE.TEMP_CHARACTERISTIC_UUID)
    
    fileprivate var centralManager: CBCentralManager?
    fileprivate var targetPeripheral: CBPeripheral? //connected periperal
    fileprivate var ctrlCharacteristic: CBCharacteristic? //ctrl for wrtiing usage
    
    fileprivate var isConnected = false
    fileprivate var hasDeviceName = false //scan with name or scan around for all devices
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    //scan all around devices
    public func scan() {
        guard centralManager != nil && centralManager!.state == .poweredOn else {
            print("fail to start central")
            return
        }
        print("start scan")
        centralManager!.scanForPeripherals(withServices: nil, options: nil)
    }
    
    //scan with name matched device
    public func scanWithDeviceName(){
        guard centralManager != nil && centralManager!.state == .poweredOn else {
            print("fail to start central")
            return
        }
        hasDeviceName = true
        print("start scan with device name")
        centralManager!.scanForPeripherals(withServices: nil, options: nil)
    }
    
    public func stopScan() {
        centralManager?.stopScan()
    }
    
    public func connect(peripheral: CBPeripheral?) {
        if targetPeripheral == nil {
            targetPeripheral = peripheral
        }
        guard targetPeripheral != nil else {
            print("No connected peripheral")
            return
        }
        centralManager?.connect(peripheral!, options: nil)
        centralManager?.stopScan()
    }
    
    public func writePeripheral(num: UInt8){
        guard targetPeripheral != nil && targetPeripheral?.state == .connected else {
            print("no peripheral connected")
            return
        }
        guard ctrlCharacteristic != nil else {
            print("no ctrl characteristic")
            return
        }
        let data = Data(from: num)
        targetPeripheral?.writeValue(data, for: ctrlCharacteristic!, type: .withResponse)
    }
    
    public func disconnect() {
        if let peripheral = targetPeripheral {
            guard peripheral.state == CBPeripheralState.connected else {
                print("\(peripheral.name ?? "null") not connected.")
                return
            }
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}


extension BluetoothManager: CBCentralManagerDelegate {
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            print("ble on")
            delegate?.centralReady()
        }
        else {
            //TODO: do something like alert the user that ble is not on
        }
    }
    
    internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard peripheral.name != nil else {
            return
        }
        if hasDeviceName && peripheral.name == Constants.BLE.DEVICE_NAME{
            //find periperal
            targetPeripheral = peripheral
            centralManager?.connect(targetPeripheral!, options: nil)
            centralManager?.stopScan()
        }else {
            delegate?.didDiscover(peripheral: peripheral)
        }
    }
    
    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("did connect")
        //periperal connected
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices([serviceId])
    }
    
    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). \(error?.localizedDescription ?? "null")")
    }
    
    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard error == nil else {
            print(error!.localizedDescription)
            return
        }
        print("Stoped: \(peripheral.name ?? "null")")
        //remove periperal instance
        targetPeripheral = nil
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard (error == nil) else {
            print("Error discovering services: %@", error!.localizedDescription)
            disconnect()
            return
        }
        guard peripheral.name != nil && peripheral.name == Constants.BLE.DEVICE_NAME else {
            print("Wrong peripheral")
            disconnect()
            return
        }
        guard peripheral.services != nil else {
            print("No service found")
            disconnect()
            return
        }
        //discover characteristic
        for service in peripheral.services! {
            if service.uuid == serviceId {
                print("find service: \(service.uuid)")
                peripheral.discoverCharacteristics([PPGCharacteristicId, TempCharacteristicId, CtrlCharacteristicId], for: service)
            }
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard (error == nil) else {
            print("Error discovering characteristic: %@", error!.localizedDescription)
            disconnect()
            return
        }
        guard service.characteristics != nil else {
            print("No characteristics found")
            disconnect()
            return
        }
        for characteristic in service.characteristics! {
            print(characteristic.uuid)
            if characteristic.uuid == TempCharacteristicId {
                print("Found Temp")
                //set notify
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == PPGCharacteristicId {
                print("Found PPG")
                //set notify
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == CtrlCharacteristicId {
                print("Found Ctrl")
                //store ctrlCharacteristic instance for writing usage
                ctrlCharacteristic = characteristic
            }
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard (error == nil) else {
            print("Error updating value: %@", error!.localizedDescription)
            disconnect()
            return
        }
        if characteristic.uuid == TempCharacteristicId {
            //only 3 byte shhould be received in temp
            guard characteristic.value?.count == 3 else {
                return
            }
            //send data notification
            let dataDic:[Int: UInt8] = [0:characteristic.value![0], 1:characteristic.value![1], 2:characteristic.value![2]]
            NotificationCenter.default.post(name: Notification.Name(Constants.NOTIFICATION.DID_RECEIVE_TEMP), object: nil, userInfo: dataDic)
        }
        
        if characteristic.uuid == PPGCharacteristicId {
            guard characteristic.value != nil else {
                return
            }
            //send data notification
            let dataDic:[Int: Data] = [0: characteristic.value!]
            NotificationCenter.default.post(name: Notification.Name(Constants.NOTIFICATION.DID_RECEIVE_PPG), object: nil, userInfo: dataDic)
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard (error == nil) else {
            print("error in writing characteristic: \(characteristic.uuid) and error: \(error!.localizedDescription)")
            disconnect()
            return
        }
    }
}
