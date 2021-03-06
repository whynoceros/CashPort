//
//  DataController.swift
//
//  Created by Gabriel Nadel on 8/11/16.
//

import Foundation
import CoreData

public class DataController: NSObject {
    
    static let sharedInstance = DataController()
    let notificationCenter = NSNotificationCenter.defaultCenter()
    
    private override init() {}
    
    private lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.endIndex.predecessor()]
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("CashPort", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CashPort.sqlite")
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            let userInfo: [String: AnyObject] = [
                NSLocalizedDescriptionKey: "Failed to initialize the application's saved data",
                NSLocalizedFailureReasonErrorKey: "There was an error creating or loading the application's saved data",
                NSUnderlyingErrorKey: error as NSError
            ]
            
            let wrappedError = NSError(domain: "com.teamtreehouse.CoreDataError", code: 9999, userInfo: userInfo)
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            self.postAlertNotification()
            abort()
        }
        
        return coordinator
    }()
    
    public lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)

        managedObjectContext.persistentStoreCoordinator = coordinator
        
        return managedObjectContext
    }()
    
    public func saveContext() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                print("Unresolved error \(error), \(error.userInfo)")
                self.postAlertNotification()
            }
        }
    }
    
   public func deleteAllFavorites() -> Bool {
        let favoritesRequest = NSFetchRequest(entityName: "Favorite")
        var favoritesArray : [Favorite] = []
        
        do {
            
            favoritesArray = try managedObjectContext.executeFetchRequest(favoritesRequest) as! [Favorite]
            for Favorite in favoritesArray{
                managedObjectContext.deleteObject(Favorite)
                saveContext()
            }
            return true
            
        } catch let error as NSError {
            print("Error fetching all currencies: \(error)")
            self.postAlertNotification()
            return false
        }
    }
    
    public func deleteAllCurrencies() -> Bool {
        let currencyRequest = NSFetchRequest(entityName: "Currency")
        var currencyArray : [Currency] = []
        
        do {
            
            currencyArray = try managedObjectContext.executeFetchRequest(currencyRequest) as! [Currency]
            for Currency in currencyArray{
                managedObjectContext.deleteObject(Currency)
                saveContext()
            }
            return true
            
        } catch let error as NSError {
            print("Error fetching all currencies: \(error)")
            self.postAlertNotification()
            return false
        }
    }
    
    func getAllCurrencies() -> [Currency] {
        let currencyRequest = NSFetchRequest(entityName: "Currency")
        let sortByFullName = NSSortDescriptor(key: "fullName", ascending:true)
        currencyRequest.sortDescriptors = [sortByFullName]
        var currencyArray : [Currency] = []
        do {

        currencyArray = try managedObjectContext.executeFetchRequest(currencyRequest) as! [Currency]
        return currencyArray
            
        } catch let error as NSError {
        print("Error fetching all currencies: \(error)")
        self.postAlertNotification()
        return currencyArray
        }
        
    }
    
    func getCurrencyByCodeFullName(code: String, fullName: String) -> (Currency?){
        //Fetch currency by code AND fullName to eliminate risk of mismatch from updated API data
        let currencyFetch = NSFetchRequest(entityName: "Currency")
        currencyFetch.predicate = NSPredicate(format: "code == %@ AND fullName == %@", code, fullName)
        do{
            let currencyArray = try managedObjectContext.executeFetchRequest(currencyFetch) as! [Currency]
            return currencyArray[0]
        }
        catch let error as NSError {
            print("Error fetching currency by code and name: \(error)")
            self.postAlertNotification()
            return nil
        }
    }
    
    func getAllFavorites() -> [Favorite] {
        let currencyRequest = NSFetchRequest(entityName: "Favorite")
        var favoriteArray : [Favorite] = []
        do {
            favoriteArray = try managedObjectContext.executeFetchRequest(currencyRequest) as! [Favorite]
            return favoriteArray
            
        } catch let error as NSError {
            print("Error getting all favorites: \(error)")
            self.postAlertNotification()
            return favoriteArray
        }
    }
    
    func setCurrentFavorite (fromCurrency: Bool, currency: Currency) -> Void{
        //Set currently selected TO and FROM as lone "favorite" to be used to pre-populate fields on next load
        //This is overbuilt for current needs, but was built so it would be easily entensible to store list of favorites, tableview on new tab, etc...
        
        var currentFavorites: [Favorite] = DataController.sharedInstance.getAllFavorites()
        
        if currentFavorites.count == 1 {
            //Update existing favorite
            let currentFavorite: Favorite = currentFavorites[0]
            
            if fromCurrency{
                //fromCurrency was set by user
                currentFavorite.codeFROM = currency.code
                currentFavorite.fullNameFROM = currency.fullName
            }
            else{
                //toCurrency was set by user
                currentFavorite.codeTO = currency.code
                currentFavorite.fullNameTO = currency.fullName
            }
            DataController.sharedInstance.saveContext()
            return
        }
        
        if currentFavorites.count > 1 {
            //Extra Favorites have accumulated somehow, clear them out
            //Remove this safety check if extending to store list of favorites
            DataController.sharedInstance.deleteAllFavorites()
            DataController.sharedInstance.saveContext()
            currentFavorites = DataController.sharedInstance.getAllFavorites()
            print("System is accumulating Favorites, this shouldn't happen under current architecture.")
        }
        
        if currentFavorites.count == 0 {
            //No existing favorites, create one and set first value
            let newFavorite = NSEntityDescription.insertNewObjectForEntityForName(Favorite.identifier, inManagedObjectContext:self.managedObjectContext) as! Favorite
            
            if fromCurrency{
                //fromCurrency was set by user
                newFavorite.codeFROM = currency.code
                newFavorite.fullNameFROM = currency.fullName
            }
            else{
                //toCurrency was set by user
                newFavorite.codeTO = currency.code
                newFavorite.fullNameTO = currency.fullName
            }
            DataController.sharedInstance.saveContext()
            return
        }
    }
    
    func postAlertNotification(){
        self.notificationCenter.postNotificationName("UserDataAlert", object: nil)
    }
}





































