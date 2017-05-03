//
//  BluetoothVC.swift
//  whiteTiger
//
//  Created by Dongjie Zhang on 3/24/17.
//  Copyright © 2017 Zachary. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothVC: UIViewController {
    
    @IBOutlet weak var bleTable: UITableView!
    
    var bleManager: BluetoothManager?
    
    var deviceArray: Array<CBPeripheral> = [] //around devices
    
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bleManager = BluetoothManager.sharedInstance
        bleManager?.delegate = self
        
        bleTable.register(UITableViewCell.self, forCellReuseIdentifier: "BleCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    @IBAction func scanBtnPressed(_ sender: UIButton) {
        deviceArray.removeAll()
        bleTable.reloadData()
        bleManager?.scan()
    }
    
    @IBAction func stopBtnPressed(_ sender: UIButton) {
        deviceArray.removeAll()
        bleTable.reloadData()
        bleManager?.stopScan()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dashBoardPage = segue.destination as? DashboardVC {
            dashBoardPage.peripheral = deviceArray[selectedIndex]
        }
    }
}

extension BluetoothVC: BluetoothManagerDelegate {
    func didDiscover(peripheral: CBPeripheral) {
        print("device: ", peripheral.name ?? "null")
        if !deviceArray.contains(peripheral) {
            deviceArray.append(peripheral)
            bleTable.reloadData()
        }
    }
    func centralReady() {
        bleManager?.scan()
    }
}

extension BluetoothVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BleCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = deviceArray[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        performSegue(withIdentifier: "bleToDashboard", sender: nil)
    }
}

