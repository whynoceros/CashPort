//
//  ViewController.swift
//  CashPort
//
//  Created by Gabriel Nadel on 8/9/16.
//
//

import Foundation
import UIKit
import CoreData

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var fromAmountField: UITextField!
    @IBOutlet weak var fromNameLabel: UILabel!
    @IBOutlet weak var toNameLabel: UILabel!
    @IBOutlet weak var toAmountLabel: UILabel!
    var fromRate: Double = -99.9
    var toRate: Double = -99.9
    
    
    let networkingController = NetworkingController()
    var currencyArray: [Currency] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.pickerView.delegate = self
        
        refreshData(){_ in
            self.currencyArray = DataController.sharedInstance.getAllCurrencies()
            dispatch_async(dispatch_get_main_queue()) {
                self.pickerView.reloadAllComponents()
            }       
    }
    }
    
    @IBAction func setFromCurrency(){
        self.fromNameLabel.text = self.currencyArray[self.pickerView.selectedRowInComponent(0)].pickerName
        
        self.fromRate = Double(self.currencyArray[self.pickerView.selectedRowInComponent(0)].usdRate!)
        
    }
    
    @IBAction func setToCurrency(){
        self.toNameLabel.text = self.currencyArray[self.pickerView.selectedRowInComponent(0)].pickerName
        self.toRate = Double(self.currencyArray[self.pickerView.selectedRowInComponent(0)].usdRate!)
    }
    
    @IBAction func convertCurrency(){
        
        let fromAmount = Double(self.fromAmountField.text!)
        let toAmount = ((self.toRate / self.fromRate) * fromAmount!)
        self.toAmountLabel.text = String(format: "%.2f", toAmount)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshData(completion: (result: String) -> Void){
        //TODO - add loading screen, with "Success" and "Warning" messages and flow
        
        self.networkingController.downladFullNames(){_ in 
            self.networkingController.downladExchangeRates()
            completion(result:"completed")
        }
        
        }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.currencyArray.count
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.whiteColor()
        pickerLabel.text = String("   " + self.currencyArray[row].pickerName)
        pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 15)
        pickerLabel.textAlignment = NSTextAlignment.Left
        pickerLabel
        return pickerLabel
    }
    /*
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.currencyArray[row].pickerName
    }
    */
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        //No need for this currenty, setTo and setFrom buttons handle the work
    }

 
}

