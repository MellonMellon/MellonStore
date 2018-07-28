//
//  NSQuery.swift
//  Boardnox
//
//  Created by Thomas Favre on 01/09/2017.
//  Copyright © 2017 Oodrive. All rights reserved.
//

import Foundation
import CoreData

@objc protocol IElasticQuery {

	func loadMore() -> [NSManagedObject]
}

@objc protocol IQuery {

	func all() -> [NSManagedObject]
	func first() -> NSManagedObject?
	func last() -> NSManagedObject?

	@discardableResult func distinct(on: String?) -> IQuery
	/// Use this property to set the limit of the number of objects to fetch
	 @discardableResult func limit(_ x: Int) -> IQuery

	 @discardableResult func offset(_ x: Int) -> IQuery

	 @discardableResult func fetchBatchSize(_ x: Int) -> IQuery

	 @discardableResult func prefetch(relations: [String]) -> IQuery

	 @discardableResult func faults(returnsFaults: Bool) -> IQuery

	 @discardableResult func refresh(refreshRefetchedObjects: Bool) -> IQuery

	 @discardableResult func groupBy(properties: [AnyObject]) -> IQuery
	/// Use this property to restrict the properties of entity A to fetch
	/// from the store
	 @discardableResult func fetch(_ properties: [AnyObject]) -> IQuery

	 @discardableResult func inManagedObjectContext(managedObjectContext: NSManagedObjectContext) -> IQuery

	 func toFetchedResultsController(
	sectionNameKeyPath: String?,
	cacheName: String?) -> NSFetchedResultsController<NSFetchRequestResult>

	/// Assign sorting order to the query results
	///
	/// - parameter sortStr: The string describing the sort order of the query results
	/// (e.g: "age ASC", "age", "age ASC, id DESC")
	/// :return IQuery
	 @discardableResult func sort(_ sortStr: String) -> IQuery

	/// restrict the results to objects where :key's value is contained in :objects
	///
	/// - parameter key: the entity's property name
	/// - parameter containedIn: the values to match againsts
	/// :return: IQuery
	 @discardableResult func with(_ key: String, containedIn objects: [AnyObject]) -> IQuery

	/// restrict the results to objects where :key's value is not contained in :objects
	///
	/// - parameter key: the entity's property name
	/// - parameter notContainedIn: the values to match againsts
	/// :return: IQuery
	 @discardableResult func with(_ key: String, notContainedIn objects: [AnyObject]) -> IQuery

	/// restrict the results to objects where :key's value contains the sequence string
	///
	/// - parameter key: the entity's property name
	/// - parameter value: the sequence to match
	/// - parameter caseSensitive: consider the search case sensitive
	/// - parameter diacriticSensitive: consider the search diacritic sensitive
	/// :return: IQuery
	 @discardableResult func with(_ key: String, containing value: String) -> IQuery

	/// restrict the results to objects where :key's value is LIKE the given pattern
	///
	/// - parameter key: the entity's property name
	/// - parameter LIKE: pattern
	/// - parameter caseSensitive: consider the search case sensitive
	/// - parameter diacriticSensitive: consider the search diacritic sensitive
	/// :return: IQuery
	 @discardableResult func with(_ key: String, like value: String) -> IQuery

	/// restrict the results to objects where :key's set/array contains all the given values
	///
	/// - parameter key: the entity's property name
	/// - parameter values: the values the entity's set/array must contain
	/// :return: IQuery
	 @discardableResult func with(_ key: String, containingAll values: [AnyObject]) -> IQuery

	/// restrict the results to objects where :key's set/array contains none of the given values
	///
	/// - parameter key: the entity's property name
	/// - parameter values: the values the entity's set/array must not contain
	/// :return: IQuery
	 @discardableResult func with(_ key: String, containingNone values: [AnyObject]) -> IQuery

	/// restrict the results to objects where :key's set/array contains any of the given values
	///
	/// - parameter key: the entity's property name
	/// - parameter values: the values the entity's set/array can contain
	/// :return: IQuery
	 @discardableResult func with(_ key: String, containingAny values: [AnyObject]) -> IQuery

	/// restrict the results to objects where :key's must exist or not
	///
	/// - parameter key: the entity's property name
	/// - parameter exists: true if the key must exists, false otherwise
	/// :return: IQuery
	 @discardableResult func with(_ key: String, existing exists: Bool) -> IQuery

	/// restrict the results to objects where :key's must have the given suffix
	///
	/// - parameter key: the entity's property name
	/// - parameter endingWith: the suffix
	/// - parameter caseSensitive: consider the search case sensitive
	/// - parameter diacriticSensitive: consider the search diacritic sensitive
	/// :return: IQuery
	 @discardableResult func with(_ key: String, endingWith suffix: String) -> IQuery

	/// restrict the results to objects where :key's must have the given prefix
	///
	/// - parameter key: the entity's property name
	/// - parameter startingWith: the prefix
	/// - parameter caseSensitive: consider the search case sensitive
	/// - parameter diacriticSensitive: consider the search diacritic sensitive
	/// :return: IQuery
	 @discardableResult func with(_ key: String, startingWith prefix: String) -> IQuery

	/// restrict the results to objects where :key's must be equal to the given value
	///
	/// - parameter key: the entity's property name
	/// - parameter equalTo: the value
	/// - parameter caseSensitive: consider the search case sensitive
	/// - parameter diacriticSensitive: consider the search diacritic sensitive
	/// :return: IQuery
	 @discardableResult func with(_ key: String, equalTo value: AnyObject?) -> IQuery

	/// restrict the results to objects where :key's must not be equal to the given value
	///
	/// - parameter key: the entity's property name
	/// - parameter equalTo: the value
	/// - parameter caseSensitive: consider the search case sensitive
	/// - parameter diacriticSensitive: consider the search diacritic sensitive
	/// :return: IQuery
	 @discardableResult func with(_ key: String, notEqualTo value: AnyObject?) -> IQuery

	/// restrict the results to objects where :key's must not be greater than the value
	///
	/// - parameter key: the entity's property name
	/// - parameter greaterThan: the value
	/// :return: IQuery
	 @discardableResult func with(_ key: String, greaterThanDouble value: Double) -> IQuery


	@discardableResult func with(_ key: String, greaterThanDate value: NSDate) -> IQuery

	/// restrict the results to objects where :key's must not be greater than or equal the value
	///
	/// - parameter key: the entity's property name
	/// - parameter greaterThanOrEqual: the value
	/// :return: IQuery
	 @discardableResult func with(_ key: String, greaterThanOrEqualDouble value: Double) -> IQuery

	 @discardableResult func with(_ key: String, greaterThanOrEqualDate value: NSDate) -> IQuery

	/// restrict the results to objects where :key's must not be greater than the value
	///
	/// - parameter key: the entity's property name
	/// - parameter greaterThan: the value
	/// :return: IQuery
	 @discardableResult func with(_ key: String, greaterThanInteger value: Int) -> IQuery

	/// restrict the results to objects where :key's must not be greater than or equal the value
	///
	/// - parameter key: the entity's property name
	/// - parameter greaterThanOrEqual: the value
	/// :return: IQuery
	 @discardableResult func with(_ key: String, greaterThanOrEqualInteger value: Int) -> IQuery

	/// restrict the results to objects where :key's must not be lower than the value
	///
	/// - parameter key: the entity's property name
	/// - parameter lowerThan: the value
	/// :return: IQuery
	 @discardableResult func with(_ key: String, lowerThanDouble value: Double) -> IQuery

	@discardableResult func with(_ key: String, lowerThanDate value: NSDate) -> IQuery
	/// restrict the results to objects where :key's must not be lower than or equal the value
	///
	/// - parameter key: the entity's property name
	/// - parameter lowerThanOrEqual: the value
	/// :return: IQuery
	 @discardableResult func with(_ key: String, lowerThanOrEqualDouble value: Double) -> IQuery

	/// restrict the results to objects where :key's must not be lower than the value
	///
	/// - parameter key: the entity's property name
	/// - parameter lowerThan: the value
	/// :return: IQuery
	 @discardableResult func with(_ key: String, lowerThanInteger value: Int) -> IQuery

	/// restrict the results to objects where :key's must not be lower than or equal the value
	///
	/// - parameter key: the entity's property name
	/// - parameter lowerThanOrEqual: the value
	/// :return: IQuery
	 @discardableResult func with(_ key: String, lowerThanOrEqualInteger value: Int) -> IQuery

	@discardableResult func with(_ key: String, lowerThanOrEqualDate value: NSDate) -> IQuery

	/// Execute the fetch request as a count operation
	///
	/// :return: the number of objects matching against query
	 func count() -> Int

	 func delete()

	@available(iOS 9.0, *)
	 func batchDelete()

	/// Execute the fetch request and return its objects
	/// :return: [objects]
	 func execute() -> [NSManagedObject]
}

@objc class NSQuery: NSObject, IQuery {

	private var query: Query<NSManagedObject>! //(NSManagedObject.self)

	public static func `for`(entity: NSManagedObject.Type) -> NSQuery {
		return NSQuery(entityName: entity.description())
	}

	public static func `for`(entityName: String) -> NSQuery {
		return NSQuery(entityName: entityName)
	}

	public static func `for`(entity: NSManagedObject.Type, context: NSManagedObjectContext) -> NSQuery {
		return NSQuery(entityName: entity.description(), context: context)
	}

	public static func `for`(entityName: String, context: NSManagedObjectContext) -> NSQuery {
		return NSQuery(entityName: entityName, context: context)
	}

	init(entityName: String, context: NSManagedObjectContext) {
		query = Query(entityName, context: context)
		super.init()
	}

	init(entityName: String) {
		query = Query(entityName)
		super.init()
	}

	func all() -> [NSManagedObject] {
		return query.all()
	}
	func first() -> NSManagedObject? {
		return query.first()
	}

	func last() -> NSManagedObject? {
		return query.last()
	}

	@discardableResult func distinct(on: String?) -> IQuery {
		_ = query.distinct()
		return self
	}

	@discardableResult func limit(_ x: Int) -> IQuery {
		_ = query.limit(x)
		return self
	}

	@discardableResult func offset(_ x: Int) -> IQuery {
		_ = query.offset(x)
		return self
	}

	@discardableResult func fetchBatchSize(_ x: Int) -> IQuery {
		_ = query.fetchBatchSize(x)
		return self
	}

	@discardableResult func prefetch(relations: [String]) -> IQuery {
		_ = query.prefetch(relations: relations)
		return self
	}

	@discardableResult func faults(returnsFaults: Bool) -> IQuery {
		_ = query.faults(returnsFaults: returnsFaults)
		return self
	}

	@discardableResult func refresh(refreshRefetchedObjects: Bool) -> IQuery {
		_ = query.refresh(refreshRefetchedObjects: refreshRefetchedObjects)
		return self
	}


	@discardableResult func groupBy(properties: [AnyObject]) -> IQuery {
		_ = query.groupBy(properties: properties)
		return self
	}

	@discardableResult func fetch(_ properties: [AnyObject]) -> IQuery {
		_ = query.fetch(properties)
		return self
	}

	@discardableResult func inManagedObjectContext(managedObjectContext: NSManagedObjectContext) -> IQuery {
		_ = query.inManagedObjectContext(managedObjectContext: managedObjectContext)
		return self
	}

	func toFetchedResultsController(
		sectionNameKeyPath: String?,
		cacheName: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
		return query.toFetchedResultsController(sectionNameKeyPath:sectionNameKeyPath, cacheName: cacheName)
	}

	func toFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {
		return query.toFetchedResultsController()
	}

	@discardableResult func sort(_ sortStr: String) -> IQuery {
		_ = query.sort(sortStr)
		return self
	}

	@discardableResult func with(_ key: String, containedIn objects: [AnyObject]) -> IQuery {
		_ = query.with(key, containedIn: objects)
		return self
	}

	@discardableResult func with(_ key: String, notContainedIn objects: [AnyObject]) -> IQuery {
		_ = query.with(key, notContainedIn: objects)
		return self
	}

	@discardableResult func with(_ key: String, containing value: String) -> IQuery {
		_ = query.with(key, containing: value)
		return self
	}

	@discardableResult func with(_ key: String, like value: String) -> IQuery {
		_ = query.with(key, like: value)
		return self
	}

	@discardableResult func with(_ key: String, containingAll values: [AnyObject]) -> IQuery {
		_ = query.with(key, containingAll: values)
		return self
	}

	@discardableResult func with(_ key: String, containingNone values: [AnyObject]) -> IQuery {
		_ = query.with(key, containingNone: values)
		return self
	}

	@discardableResult func with(_ key: String, containingAny values: [AnyObject]) -> IQuery {
		_ = query.with(key, containingAny: values)
		return self
	}

	@discardableResult func with(_ key: String, existing exists: Bool) -> IQuery {
		_ = query.with(key, existing: exists)
		return self
	}

	@discardableResult func with(_ key: String, endingWith suffix: String) -> IQuery {
		_ = query.with(key, endingWith: suffix)
		return self
	}

	@discardableResult func with(_ key: String, startingWith prefix: String) -> IQuery {
		_ = query.with(key, startingWith: prefix)
		return self
	}

	@discardableResult func with(_ key: String, equalTo value: AnyObject?) -> IQuery {
		_ = query.with(key, equalTo: value)
		return self
	}

	@discardableResult func with(_ key: String, notEqualTo value: AnyObject?) -> IQuery {
		_ = query.with(key, notEqualTo: value)
		return self
	}

	@discardableResult func with(_ key: String, greaterThanDouble value: Double) -> IQuery {
		_ = query.with(key, greaterThan: value)
		return self
	}

	@discardableResult func with(_ key: String, greaterThanDate value: NSDate) -> IQuery {
		_ = query.with(key, greaterThan: value as Date)
		return self
	}

	@discardableResult func with(_ key: String, greaterThanOrEqualDate value: NSDate) -> IQuery  {
		_ = query.with(key, greaterThanOrEqual: value as Date)
		return self
	}


	@discardableResult func with(_ key: String, greaterThanOrEqualDouble value: Double) -> IQuery  {
		_ = query.with(key, greaterThanOrEqual: value)
		return self
	}

	@discardableResult func with(_ key: String, greaterThanInteger value: Int) -> IQuery {
		_ = query.with(key, greaterThan: value)
		return self
	}

	@discardableResult func with(_ key: String, greaterThanOrEqualInteger value: Int) -> IQuery {
		_ = query.with(key, greaterThanOrEqual: value)
		return self
	}

	@discardableResult func with(_ key: String, lowerThanDouble value: Double) -> IQuery {
		_ = query.with(key, lowerThan: value)
		return self
	}

	@discardableResult func with(_ key: String, lowerThanDate value: NSDate) -> IQuery {
		_ = query.with(key, lowerThan: value as Date)
		return self
	}

	@discardableResult func with(_ key: String, lowerThanOrEqualDouble value: Double) -> IQuery {
		_ = query.with(key, lowerThanOrEqual: value)
		return self
	}

	@discardableResult func with(_ key: String, lowerThanInteger value: Int) -> IQuery {
		_ = query.with(key, lowerThan: value)
		return self
	}

	@discardableResult func with(_ key: String, lowerThanOrEqualInteger value: Int) -> IQuery {
		_ = query.with(key, lowerThanOrEqual: value)
		return self
	}

	@discardableResult func with(_ key: String, lowerThanOrEqualDate value: NSDate) -> IQuery {
		_ = query.with(key, lowerThanOrEqual: value as Date)
		return self
	}

	func count() -> Int {
		return query.count()
	}

	func delete() {
		return query.delete()
	}

	@available(iOS 9.0, *)
	func batchDelete() {
		return query.batchDelete()
	}

	func execute() -> [NSManagedObject] {
		return query.execute()
	}
}
