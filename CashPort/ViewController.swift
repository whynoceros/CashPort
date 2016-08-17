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
    
    //Initial values set to negatives for ease in debugging and validation checks
    var fromRate: Double = -99.9
    var toRate: Double = -99.9
    
    let networkingController = NetworkingController()
    var currencyArray: [Currency] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(userDataAlert), name: "UserDataAlert", object: nil)
        self.pickerView.delegate = self
        addDoneButtonOnKeyboard()
        reloadAll()
    }
    
    @IBAction func setFromCurrency(){
        //Set FROM currency in UI, conversion calculator and saved favorite
        self.fromNameLabel.text = self.currencyArray[self.pickerView.selectedRowInComponent(0)].pickerName
        self.fromRate = Double(self.currencyArray[self.pickerView.selectedRowInComponent(0)].usdRate!)
        DataController.sharedInstance.setCurrentFavorite(true, currency:self.currencyArray[self.pickerView.selectedRowInComponent(0)])
        
    }
    
    @IBAction func setToCurrency(){
        //Set TO currency in UI, conversion calculator and saved favorite
        self.toNameLabel.text = self.currencyArray[self.pickerView.selectedRowInComponent(0)].pickerName
        self.toRate = Double(self.currencyArray[self.pickerView.selectedRowInComponent(0)].usdRate!)
        DataController.sharedInstance.setCurrentFavorite(false, currency:self.currencyArray[self.pickerView.selectedRowInComponent(0)])
    }
    
    @IBAction func convertCurrency(){
        let isValid = inputValidation()
        //If inputs are valid procede with conversion, if not return early
        if !isValid {
            return
        }
        let fromAmount = Double(self.fromAmountField.text!)
        let toAmount = ((self.toRate / self.fromRate) * fromAmount!)
        self.toAmountLabel.text = String(format: "%.2f", toAmount)
    }
    
    @IBAction func reloadAll(){
        showLoadingScreen()
        refreshDataAndUI(){_ in
            self.currencyArray = DataController.sharedInstance.getAllCurrencies()
        }
    }
    
    func setLastUpdatedLabel(){
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm aa"
        let date = NSDate()
        let dateString = dateFormatter.stringFromDate(date)
        self.lastUpdatedLabel.text = "   Last Updated:\n   \(dateString)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func refreshDataAndUI(completion: (result: String) -> Void){
        //Pull data from endpoints, create new set of CoreData currency entities, assign rates, trigger UI refreshes and hide loadingScreen
        
        self.networkingController.downladFullNames(){_ in 
            self.networkingController.downladExchangeRates(){
                _ in
                dispatch_async(dispatch_get_main_queue()) {
                    self.pickerView.reloadAllComponents()
                    self.setDefaultCurrencies()
                    self.hideLoadingScreen()
                    self.setLastUpdatedLabel()
                }
            completion(result:"completed")
            }
            completion(result:"completed")
            }
    }
    
    func setDefaultCurrencies(){
        //Check for lone "Favorite", which is updated after every new TO or FROM currency is set
        //Current architecture can be extended to handle a list of favorites with minor changes
        
        var currentFavorites: [Favorite] = DataController.sharedInstance.getAllFavorites()
        if currentFavorites.count == 1 {
            //Only set default if exactly one favorite exists, otherwise do not prepopulate fields
            
            let currentFavorite: Favorite = currentFavorites[0]
            if currentFavorite.codeFROM != nil {
                //Fetch FROM currency based on code and fullName match - uses a combination of currency code and full name to eliminate the chance of displaying an incorrect currency or mismatched rate given code/name changes from the API since last session
                
                if let fromCurrency =  DataController.sharedInstance.getCurrencyByCodeFullName(currentFavorite.codeFROM!, fullName: currentFavorite.fullNameFROM!){
                    //set FROM currency
                    self.fromNameLabel.text = fromCurrency.pickerName
                    self.fromRate = Double(fromCurrency.usdRate!)
                }
            }
            if currentFavorite.codeTO != nil {
                //fetch TO currency based on code and fullName match - uses a combination of currency code and full name, to eliminate the chances of displaying a currency where the API code has changed
                
                if let toCurrency =  DataController.sharedInstance.getCurrencyByCodeFullName(currentFavorite.codeTO!, fullName: currentFavorite.fullNameTO!){
                    //set TO currency
                    self.toNameLabel.text = toCurrency.pickerName
                    self.toRate = Double(toCurrency.usdRate!)
                }
            }
        }
    }
    
    func inputValidation() -> Bool{
        //Check for valid inputs, display custom alerts
        let alert = UIAlertController(title: nil, message: "Invalid Input", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: { (action: UIAlertAction!) in
        }))
        var message = "Invalid Input"
        var invalidCount = 0
        
        //Alerts for single invalid inputs
        if self.fromRate <= 0 {
            invalidCount += 1
            message = "Please select a 'FROM' currency"
        }
        if self.toRate <= 0 {
            invalidCount += 1
            message = "Please select a 'TO' currency"
        }
        if self.toNameLabel.text == self.fromNameLabel.text {
            invalidCount += 1
            message = "It looks like your 'TO' and FROM currencies are the same."
        }
        if Double(self.fromAmountField.text!) <= 0 {
            invalidCount += 1
            message = "Please enter a valid amount (no negatives, commas or symbols"
        }
        //Alert for multiple invalid inputs
        if invalidCount > 1 {
            message = "Please enter a valid amount and select both 'TO' and 'FROM' currencies"
        }
        if invalidCount > 0 {
            alert.message = message
            presentViewController(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.currencyArray.count
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView
    {
        //Set custom picker style, allow for padding on left
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.whiteColor()
        pickerLabel.text = String("   " + self.currencyArray[row].pickerName)
        pickerLabel.font = UIFont(name: "Kohinoor Bangla", size: 15)
        pickerLabel.textAlignment = NSTextAlignment.Left
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
        //Add "Done" button to default Numeric Keypad
        let navBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.width, 44))
        navBar.barStyle = UIBarStyle.BlackTranslucent;
        navBar.backgroundColor = UIColor.lightGrayColor();
        navBar.alpha = 1.0;
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
    
    func userDataAlert(){
        dispatch_async(dispatch_get_main_queue()) {
        let alert = UIAlertController(title: "Warning", message: "Data did not update properly. Please close and relaunch the app.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: { (action: UIAlertAction!) in
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    }
}

