//
//  CoreDataStack.swift
//
//  Created by Pasan Premaratne on 6/15/16.
//  Copyright © 2016 Treehouse. All rights reserved.
//

import Foundation
import CoreData

public class DataController: NSObject {
    
    static let sharedInstance = DataController()
    
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
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("TodoList.sqlite")
        
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
            abort()
        }
        
        return coordinator
    }()
    
    public lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        
        managedObjectContext.persistentStoreCoordinator = coordinator
        
        return managedObjectContext
    }()
    
    public func saveContext() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    public func deleteAllInstances(entityName: String) -> Bool {
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        var success = false
        do {
            try persistentStoreCoordinator.executeRequest(deleteRequest, withContext: managedObjectContext)
            success = true
        } catch let error as NSError {
           success = false
        }
        return success
    }
    
    public func getAllEntities(entityName: String) throws -> [AnyObject]? {
        let entityRequest = NSFetchRequest(entityName: entityName)
        var entityArray : [AnyObject] = []
        do {
        
        entityArray = try managedObjectContext.executeFetchRequest(entityRequest) as! [AnyObject]
        return entityArray
            
        } catch let error as NSError {
        return nil
        }
    }
}





































