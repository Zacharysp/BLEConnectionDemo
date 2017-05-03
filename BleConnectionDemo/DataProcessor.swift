//
//  DataProcessor.swift
//  whiteTiger
//
//  Created by Dongjie Zhang on 3/28/17.
//  Copyright © 2017 Zachary. All rights reserved.
//

import Foundation

class DataProcessor: NSObject{
    var ppgArray: Array<Int> = []
    var ppg1Array: Array<Int> = []
    
    private var currentPayload: PayloadData?
    
    override init() {
        super.init()
        renewPayload()
    }
    
    //received new segment data
    func processNewSegment(segData: Data) {
        guard currentPayload != nil else {
            return
        }
        //designed each segment has 20 bytes, if need to check on the segment data size, uncomment following line
        //let count = segData.count / MemoryLayout<UInt8>.size
        // create an array of Uint8 with size of 20
        var dataBytes = Array<UInt8>(repeating: 0, count: 20)
        // copy bytes into array
        segData.copyBytes(to: &dataBytes, count: 20)
        
        let segHeader = dataBytes[0]
        let lastSegFlag = segHeader >> 7
        let payloadNum = (segHeader - (lastSegFlag << 7)) >> 3
        let segNum = segHeader - (payloadNum << 3) - (lastSegFlag << 7)
        let data = segData.subdata(in: Range(1..<segData.count))
        
        //brand new payload
        if currentPayload!.isNew() {
            currentPayload?.payloadNum = Int(payloadNum)
        }
        
        //check if this segment is for same payload
        if currentPayload!.payloadNum != Int(payloadNum) {
            print("Incoming wrong payload")
            //drop old payload
            renewPayload()
        }
        
        if lastSegFlag == 0 {
            //append to payload
            currentPayload?.appendSegment(segData: data, segNum: Int(segNum))
        }else {
            //receive last segment, decode payload and add to ppg array
            let payloadData = currentPayload?.appendLastSegment(segData: data, segNum: Int(segNum))
            //finish current payload and renew
            renewPayload()
            guard payloadData != nil else {
                //wrong data, drop this payload
                return
            }
            processPPGPackage(data: payloadData! as Data)
        }
    }
    
    //restart a new payload
    private func renewPayload(){
        currentPayload = PayloadData()
    }
    
    //finish payload, and process payload package to ppg array
    private func processPPGPackage(data: Data){
        guard data.count % 6 == 0 else {
            print("package data cannot divide exactly with 6, drop this payload")
            return
        }
        let totalPPGNum = data.count / 3
        for index in 0..<totalPPGNum {
            let startIndex = index*3
            let endIndex = startIndex + 3
            let value = buildInt(data: data.subdata(in: startIndex..<endIndex))
            appendToPPG(value: value, index: index)
        }
    }
    
    //convert 3 bytes data to Int
    private func buildInt(data: Data) -> Int{
        let high = UInt32(data[2]) << 16
        let mid = UInt32(data[1]) << 8
        let low = UInt32(data[0])
        return Int(high + mid + low)
    }
    
    //append to ppg and ppg1 array
    private func appendToPPG(value: Int, index: Int) {
        if index % 2 == 0 {
            ppgArray.append(value)
        }else {
            ppg1Array.append(value)
        }
    }
}

class PayloadData: NSObject {
    var payloadNum: Int = 0
    
    private var segmentCount: Int = 0
    private var segmentDic: [Int: Data]?
    
    //append new segment data to package
    func appendSegment(segData: Data, segNum: Int){
        if segmentDic == nil {
            segmentDic = [:]
        }
        segmentDic![segNum] = segData
        segmentCount = segmentCount + 1
    }
    
    //append last segment data and return whole data package
    func appendLastSegment(segData: Data, segNum: Int) -> NSMutableData?{
        appendSegment(segData: segData, segNum: segNum)
        return buildPayload()
    }
    
    //check if this is a new payload
    func isNew() -> Bool {
        return segmentDic == nil
    }
    
    //iterate all segments data to output payload data
    private func buildPayload() -> NSMutableData?{
        guard segmentDic != nil else {
            return nil
        }
        let totalSegmentCount = segmentDic!.count
        let package = NSMutableData()
        for index in 0 ..< totalSegmentCount {
            if let data = segmentDic![index] {
                package.append(data)
            }else {
                print("missing segment")
                return nil
            }
        }
        return package
    }
    
}
