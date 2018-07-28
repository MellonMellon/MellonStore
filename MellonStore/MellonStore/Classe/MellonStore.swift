//
//  MellonStore.swift
//  MellonStore
//
//  Created by Thomas Favre on 28/07/2017.
//  Copyright © 2017 adibou. All rights reserved.
//

import Foundation
import CoreData

precedencegroup FetchPrecedence {
	associativity: right
}

infix operator <<: FetchPrecedence

@objc public class MellonStore: NSObject {

	typealias CoreDataManagerCompletion = () -> ()

	public static var `default`: MellonStore!
  public static var modelName: String!
  
	fileprivate let storeName: String
	fileprivate let extensionName: String
	fileprivate let completion: CoreDataManagerCompletion?

	fileprivate var persistentStoreURL: URL {
		let storeName = "\(self.storeName).sqlite"
		let fileManager = FileManager.default
		let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

		return documentsDirectoryURL.appendingPathComponent(storeName)
	}

	fileprivate lazy var managedObjectModel: NSManagedObjectModel? = {
		// Fetch Model URL
    guard let modelURL = Bundle.main.url(forResource: MellonStore.modelName, withExtension: self.extensionName) else {
			return nil
		}

		// Initialize Managed Object Model
		let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)

		return managedObjectModel
	}()

	var entities:  [NSEntityDescription] {
		return managedObjectModel?.entities ?? []
	}

	@available(iOS 10.0, *)
	lazy var mockPersistantContainer: NSPersistentContainer = {

		let container = NSPersistentContainer(name: "PersistentTodoList", managedObjectModel: self.managedObjectModel!)
		let description = NSPersistentStoreDescription()
		description.type = NSInMemoryStoreType
		description.shouldAddStoreAsynchronously = false // Make it simpler in test env

		container.persistentStoreDescriptions = [description]
		container.loadPersistentStores { (description, error) in
			// Check if the data store is in memory
			precondition( description.type == NSInMemoryStoreType )

			// Check if creating container wrong
			if let error = error {
				fatalError("Create an in-mem coordinator failed \(error)")
			}
		}
		return container
	}()

	fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
		guard let managedObjectModel = self.managedObjectModel else {
			return nil
		}

		// Initialize Persistent Store Coordinator
		let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		return persistentStoreCoordinator
	}()

	private lazy var privateManagedObjectContext: NSManagedObjectContext = {
		// Initialize Managed Object Context
		let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

		// Configure Managed Object Context
		managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator

		managedObjectContext.retainsRegisteredObjects = true

		return managedObjectContext
	}()

	public private(set) lazy var mainManagedObjectContext: NSManagedObjectContext = {
		// Initialize Managed Object Context
		let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

		// Configure Managed Object Context
		managedObjectContext.parent = self.privateManagedObjectContext
		managedObjectContext.retainsRegisteredObjects = true

		return managedObjectContext
	}()

  init(storeName: String, withExtension extensionName: String = "momd", inMemory: Bool = false, completion: CoreDataManagerCompletion? = nil) throws {
    self.storeName = storeName
		self.completion = completion
		self.extensionName = extensionName

		super.init()
		initialize()
    if completion == nil {
      synchroneSetupMellonStore(inMemory: inMemory)
    } else {
      setupMellonStore(inMemory: inMemory)
    }
	}

  static func setup(storeName: String = MellonStore.modelName, withExtension extensionName: String = "momd", inMemory: Bool = false, completion: CoreDataManagerCompletion? = nil) {
    MellonStore.default = try! MellonStore(storeName: storeName, withExtension: extensionName, inMemory: inMemory, completion: completion)
	}
  
	deinit {
		unregisterForManagedObjectContextNotifications()
	}

	public func initialize() {
		registerForManagedObjectContextNotifications(managedObjectContext: mainManagedObjectContext)
		registerForManagedObjectContextNotifications(managedObjectContext: privateManagedObjectContext)
	}

	fileprivate func setupMellonStore(inMemory: Bool = false) {
		// Fetch Persistent Store Coordinator
		_ = mainManagedObjectContext.persistentStoreCoordinator

		DispatchQueue.global().async {
			// Add Persistent Store
			if inMemory {
				self.addInMemoryStore()
			} else {
				self.addPersistentStore()
			}

			// Invoke Completion On Main Queue
			DispatchQueue.main.async { self.completion?() }
		}
	}

	fileprivate func synchroneSetupMellonStore(inMemory: Bool = false) {
		_ = mainManagedObjectContext.persistentStoreCoordinator
		if inMemory {
			self.addInMemoryStore()
		} else {
			self.addPersistentStore()
		}
		self.completion?()
	}

	fileprivate func addInMemoryStore() {
		guard let persistentStoreCoordinator = persistentStoreCoordinator else { fatalError("Unable to Initialize Persistent Store Coordinator") }

		// Helper
		let persistentStoreURL = self.persistentStoreURL

		do {
			let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]
			try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: persistentStoreURL, options: options)

		} catch {
			let addPersistentStoreError = error as NSError
			print("Unable to Add Persistent Store")
			print("\(addPersistentStoreError.localizedDescription)")
		}
	}

	fileprivate func addPersistentStore() {
		guard let persistentStoreCoordinator = persistentStoreCoordinator else { fatalError("Unable to Initialize Persistent Store Coordinator") }

		// Helper
		let persistentStoreURL = self.persistentStoreURL

		do {
			let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]
			try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreURL, options: options)

		} catch {
			let addPersistentStoreError = error as NSError
			print( "Unable to Add Persistent Store")
			print("\(addPersistentStoreError.localizedDescription)")
		}

	}

	public func newBackgroundContext() -> NSManagedObjectContext {
		// Initialize Managed Object Context
		let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

		// Configure Managed Object Context
		managedObjectContext.parent = mainManagedObjectContext
		managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		registerForManagedObjectContextNotifications(managedObjectContext: managedObjectContext)

		return managedObjectContext
	}

	func transaction(_ block: @escaping (NSManagedObjectContext) -> Void) {
		let context = newBackgroundContext()
		context.performAndWait {
			block(context)
			do {
				try context.save()
			}
			catch let error {
				print("\(error.localizedDescription)")
			}
		}
	}
	
  //MARK: - Store Manipulation
  
	static func switchTo(storeIdentifier: String, withExtension extensionName: String = "momd", completion: @escaping CoreDataManagerCompletion) {
		let storeName = "\(storeIdentifier)"
		MellonStore.default = try! MellonStore(storeName: storeName, withExtension: extensionName, completion: completion)
	}

	static func switchTo(storeIdentifier: String, withExtension extensionName: String = "momd") {
		let storeName = "\(storeIdentifier)"
		MellonStore.default = try! MellonStore(storeName: storeName, withExtension: extensionName)
	}


	func copyStore(for storeIdentifier: String) throws {
		let storeName = "\(storeIdentifier)"
		let fileManager = FileManager.default
		let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let url = documentsDirectoryURL.appendingPathComponent(storeName)

		if !fileManager.fileExists(atPath: (url.path)) {
			let seededDataUrl =  documentsDirectoryURL.appendingPathComponent(self.storeName + ".sqlite")
			let seededDataUrl2 = documentsDirectoryURL.appendingPathComponent(self.storeName + ".sqlite-shm")
			let seededDataUrl3 = documentsDirectoryURL.appendingPathComponent(self.storeName + ".sqlite-wal")

			try fileManager.copyItem(at: seededDataUrl, to: documentsDirectoryURL.appendingPathComponent(storeName + ".sqlite"))
			try fileManager.copyItem(at: seededDataUrl2, to: documentsDirectoryURL.appendingPathComponent(storeName + ".sqlite-shm"))
			try fileManager.copyItem(at: seededDataUrl3, to: documentsDirectoryURL.appendingPathComponent(storeName + ".sqlite-wal"))
		}
	}
	func deleteStore(for storeIdentifier: String) throws {
    let storeName = "\(storeIdentifier)"
		let fileManager = FileManager.default
		let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

		let seededDataUrl =  documentsDirectoryURL.appendingPathComponent(storeName + ".sqlite")
		let seededDataUrl2 = documentsDirectoryURL.appendingPathComponent(storeName + ".sqlite-shm")
		let seededDataUrl3 = documentsDirectoryURL.appendingPathComponent(storeName + ".sqlite-wal")

		try fileManager.removeItem(at: seededDataUrl)
		try fileManager.removeItem(at: seededDataUrl2)
		try fileManager.removeItem(at: seededDataUrl3)
	}

	// MARK: - Core Data Saving support

	public func saveChanges() {
		mainManagedObjectContext.performAndWait {
			do {
				if self.mainManagedObjectContext.hasChanges {
					try self.mainManagedObjectContext.save()
				}
			} catch {
				let saveError = error as NSError
				print("Unable to Save Changes of Main Managed Object Context")
				print("\(saveError), \(saveError.localizedDescription)")
			}
		}

		privateManagedObjectContext.perform {
			do {
				if self.privateManagedObjectContext.hasChanges {
					try self.privateManagedObjectContext.save()
				}
			} catch {
				let saveError = error as NSError
				print("Unable to Save Changes of Private Managed Object Context")
				print("\(saveError), \(saveError.localizedDescription)")
			}
		}
	}

	public func commit(context: NSManagedObjectContext) {
		context.perform {
			do {
				if context.hasChanges {
					try context.save()
				}
			} catch {
				let saveError = error as NSError
				print("Unable to Save Changes of Private Managed Object Context")
				print("\(saveError), \(saveError.localizedDescription)")
			}
		}
	}
}

// Notifications & Merging
extension MellonStore {

	func registerForManagedObjectContextNotifications(managedObjectContext: NSManagedObjectContext) {
		NotificationCenter
			.default
			.addObserver(
				self,
				selector: #selector(managedObjectContextDidSave),
				name: NSNotification.Name.NSManagedObjectContextDidSave,
				object: managedObjectContext)
	}

	func unregisterForManagedObjectContextNotifications(managedObjectContext: NSManagedObjectContext? = nil) {
		NotificationCenter
			.default
			.removeObserver(
				self,
				name: NSNotification.Name.NSManagedObjectContextDidSave,
				object: managedObjectContext)
	}

	@objc
	private func managedObjectContextDidSave(notification: NSNotification) {
		print("\(#function): \(String(describing: notification.object))")
		guard
			let savedManagedObjectContext = notification.object as? NSManagedObjectContext
			else { return }

		// Break retain cycles and release memory
		savedManagedObjectContext.perform {
			savedManagedObjectContext.refreshAllObjects()
		}

		guard savedManagedObjectContext.parent == self.mainManagedObjectContext
			else { return }


		if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
			for updatedObject in updatedObjects {
				_ = try? self.mainManagedObjectContext.existingObject(with: updatedObject.objectID)
			}
		}
		print( "Write to disk...")

		// Write to disk
		saveChanges()
	}


	public func fetch(entity: NSManagedObject, from context: NSManagedObjectContext) -> NSManagedObject {
		var object: NSManagedObject!
		context.performAndWait {
			object = context.object(with: entity.objectID)
		}
		return object
	}

	public func fetch(entity: NSManagedObject) -> NSManagedObject {
		var object: NSManagedObject!
		mainManagedObjectContext.performAndWait {
			object = self.mainManagedObjectContext.object(with: entity.objectID)
		}
		return object
	}
}

public func << <A: NSManagedObject>(left: NSManagedObjectContext, right: A) -> A! {
	var object: A!
	left.performAndWait {
		object = left.object(with: right.objectID) as! A
	}
	return object
}

extension NSManagedObjectContext {
  public func fetch<A: NSManagedObject>(entity: A) -> A {
    var object: A!
    self.performAndWait {
      object = self.object(with: entity.objectID) as! A
    }
    return object
  }
}
