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
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var loadingView: UIView!
    
    var fromRate: Double = -99.9
    var toRate: Double = -99.9
    
    
    let networkingController = NetworkingController()
    var currencyArray: [Currency] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pickerView.delegate = self
        addDoneButtonOnKeyboard()
        refreshDataAndUI()
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
        
        //Add check for any negatives/nils, return alert message, refresh btn
        
        let fromAmount = Double(self.fromAmountField.text!)
        let toAmount = ((self.toRate / self.fromRate) * fromAmount!)
        self.toAmountLabel.text = String(format: "%.2f", toAmount)
        
    }
    
    @IBAction func refreshDataAndUI(){
        showLoadingScreen()
        refreshData(){_ in
            self.currencyArray = DataController.sharedInstance.getAllCurrencies()
            dispatch_async(dispatch_get_main_queue()) {
                self.pickerView.reloadAllComponents()
                self.hideLoadingScreen()
                self.setLastUpdatedLabel()
            }
        }
    }
    
    func setLastUpdatedLabel(){
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm aa"
        let date = NSDate()
        //dateFormatter.dateFormat = "HH:mm"
        let dateString = dateFormatter.stringFromDate(date)
        print("time: \(dateString)")
        self.lastUpdatedLabel.text = "   Last Updated:\n   \(dateString)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshData(completion: (result: String) -> Void){
        
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
        pickerLabel.font = UIFont(name: "Kohinoor Bangla", size: 15)
        pickerLabel.textAlignment = NSTextAlignment.Left
        pickerLabel
        return pickerLabel
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        //No need for this currenty, setTo and setFrom buttons handle the work
    }
    
    func showLoadingScreen() -> Void {
        
        self.loadingView.alpha = 1
        self.loadingView.hidden = false
    }
    
    func hideLoadingScreen() -> Void {
        
        UIView.animateWithDuration(0.75, delay: 1.0, options: .CurveEaseInOut, animations: {
            self.loadingView.alpha = 0},
            completion: { finished in
                    self.loadingView.hidden = true })
    }
    
    func addDoneButtonOnKeyboard()
    {
        let navBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.width, 44))
        navBar.barStyle = UIBarStyle.BlackTranslucent;
        navBar.backgroundColor = UIColor.lightGrayColor();
        navBar.alpha = 1.0;
        //replace viewWidth with view controller width
        let navItem = UINavigationItem()
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: #selector(self.closeKeyboard))
        navItem.rightBarButtonItem = doneButton
        
        navBar.pushNavigationItem(navItem, animated: false)
        
        self.fromAmountField.inputAccessoryView = navBar
        
    }
    
    func closeKeyboard()
    {
        self.fromAmountField.resignFirstResponder()
    }
}

