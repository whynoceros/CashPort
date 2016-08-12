//
//  NetworkingController.swift
//  CashPort
//
//  Created by Gabriel Nadel on 8/9/16.
//  Copyright © 2016 Treehouse. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Freddy


class NetworkingController: NSObject{
    
    typealias Payload = [String: AnyObject]
    
    //URL Prefixes and appID provided by https://openexchangerates.org .
    //If you intend to run or modify this app, please request your own appID
    //Given the "free" status of this app, exchange rates are only update hourly
    let urlPrefixRates = "https://openexchangerates.org/api/latest.json?app_id="
    let urlPrefixFullNames = "https://openexchangerates.org/api/currencies.json?app_id="
    let appID = "db82ad7a2f1642848f56c87f103d3aae"
    let context = DataController.sharedInstance.managedObjectContext
    
    var currenciesArray = [["XYZ Code" : "Currency Name"]]
    var success = false

    func downladExchangeRates(){
        //Download exchange rate data from exchang rate endpoint
        
        let fullURL = NSURL(string: self.urlPrefixRates + self.appID)
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: fullURL!)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            if (statusCode == 200) {
                
                do{
                  let json = try JSON(data: data!)
                  let ratesDict = try json.dictionary("rates")
                    
                    for rate in ratesDict {
                        do {
                            //Fetch currency object based on code
                            let currencyFetch = NSFetchRequest(entityName: "Currency")
                            currencyFetch.predicate = NSPredicate(format: "code == %@", rate.0)
                            let currencyArray = try self.context.executeFetchRequest(currencyFetch) as! [Currency]
                            do{
                            //Set usdRate for currency object
                            currencyArray[0].usdRate = try Double(json: rate.1)
                            print("rate: \(rate)")
                            do{
                                try self.context.save()
                            }
                            catch {
                                print("try Double(json: rate.1) failed: \(error)")
                            }
                            }
                            catch{
                                print("error fetching")
                            }
                        } catch {
                            fatalError("Failed to fetch employees: \(error)")
                        }
                    }
                    print("finishedRatesLoop")
                }catch {
                    print("Error with Json: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func downladFullNames(completion: (result: String) -> Void){
        
        //Fetch and delete all existing currencies, could implement different architecture if we wanted to store historical data in the future.
        //Given that you always want the newest, safest data for currencies - or none at all - a full delete seemed least likely to present the user with a false, outdated or mismatched rates
        
        self.success = DataController.sharedInstance.deleteAllInstances("Currency")
        
        if !self.success {
            return
        }
        
        //Download exchange rate data from exchang rate endpoint
        let fullURL = NSURL(string: self.urlPrefixFullNames + self.appID)
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: fullURL!)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            if (statusCode == 200) {
                
                do{
                    let json = try JSON(data: data!)
                    let namesDict = try json.dictionary()
                    
                    for currencyName in namesDict {
                        //Create new currency entity for each currency in response
                        let currency = NSEntityDescription.insertNewObjectForEntityForName(Currency.identifier, inManagedObjectContext:self.context) as! Currency
                        //Set currency code and fullName
                        currency.code = currencyName.0
                        currency.fullName = try String(json: currencyName.1)
                        try self.context.save()
               
                    }
                    self.success = true
                    
                    completion(result:"completed")
                    
                }catch {
                    self.success = false
                }
            }
        }
        task.resume()
    }

    
    
    
}
