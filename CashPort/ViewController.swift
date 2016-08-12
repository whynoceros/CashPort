//
//  ViewController.swift
//  CashPort
//
//  Created by Gabriel Nadel on 8/9/16.
//  Copyright © 2016 Treehouse. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    let networkingController = NetworkingController()
    var currencyArray: [Currency] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        refreshData()
        try self.currencyArray = DataController.sharedInstance.getAllCurrencies()
        do{
            
        }
         catch let error as NSError{
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshData(){
        //TODO - add loading screen, with "Success" and "Warning" messages and flow
        
         self.networkingController.downladFullNames()

        }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.currencyArray.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.currencyArray[row].pickerName
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        //Insert
    }
}

