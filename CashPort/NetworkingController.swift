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
    let notificationCenter = NSNotificationCenter.defaultCenter()
    //URL Prefixes and appID provided by https://openexchangerates.org .
    //If you intend to RUN or MODIFY this app, please request your own appID from: https://openexchangerates.org it is very easy to do so
    //Given the "free" status of this app, exchange rates are only updated hourly
    let urlPrefixRates = "https://openexchangerates.org/api/latest.json?app_id="
    let urlPrefixFullNames = "https://openexchangerates.org/api/currencies.json?app_id="
    let appID = "db82ad7a2f1642848f56c87f103d3aae"
    let dataController = DataController.sharedInstance
    var currenciesArray = [["XYZ Code" : "Currency Name"]]
    
    func downladFullNames(completion: (result: String) -> Void){
        
        //Delete all existing currencies then fetch, could implement different architecture if we wanted to store historical data in the future.
        //Given that you always want the newest, safest data for currencies - or none at all - a full delete seemed least likely to present the user with a false, outdated or mismatched rates
        
       let success = DataController.sharedInstance.deleteAllInstances("Currency")
        
        if !success {
            print("Failure to delete current cureencies from CoreData")
            return
        }
        
        //Download currencies (just codes and fullNames) from FullNames endpoint
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
                        let currency = NSEntityDescription.insertNewObjectForEntityForName(Currency.identifier, inManagedObjectContext:self.dataController.managedObjectContext) as! Currency
                        //Set currency code and fullName
                        currency.code = currencyName.0
                        currency.fullName = try String(json: currencyName.1)
                        self.dataController.saveContext()
                        
                    }
                    completion(result:"completed")
                }catch {
                    
                    print("Failure to parse JSON or create new Core Data entities")
                }
            }
            else {
                self.notificationCenter.postNotificationName("UserDataAlert", object: nil)
                print("Bad response from server. Status code: \(statusCode)")
            }
        }
        task.resume()
    }


    func downladExchangeRates(completion: (result: String) -> Void){
        //Download exchange rate data from Rates endpoint
        let fullURL = NSURL(string: self.urlPrefixRates + self.appID)
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: fullURL!)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = session.dataTaskWithRequest(request) {
            data, response, error in
            
            let httpResponse = response as! NSHTTPURLResponse
            
            do{
            let statusCode = httpResponse.statusCode
            if (statusCode == 200) {
                
                  let json = try JSON(data: data!)
                  let ratesDict = try json.dictionary("rates")
                    
                    for rate in ratesDict {
                       
                            //Fetch currency object based on code
                            let currencyFetch = NSFetchRequest(entityName: "Currency")
                            currencyFetch.predicate = NSPredicate(format: "code == %@", rate.0)
                            let currencyArray = try self.dataController.managedObjectContext.executeFetchRequest(currencyFetch) as! [Currency]
                        
                            //Set usdRate for currency object
                            currencyArray[0].usdRate = try Double(json: rate.1)
                            self.dataController.saveContext()
                            }
                completion(result:"completed")
            }
            else {
                print("Bad response from server. Status code: \(statusCode)")
            }
            }
            catch let error{
                    print("Failure to parse JSON or fetch from CoreData. Error Description: \(error)")
                }
        }
        task.resume()
    }

   }
