//
//  Query.swift
//  protoCoreDataConcurrency
//
//  Created by favre on 08/08/2017.
//  Copyright © 2017 adibou. All rights reserved.
//

import Foundation
import CoreData

public struct QueryOptions: OptionSet {
  
  public let rawValue: UInt
  
  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }
  
  /*public var boolValue: Bool {
   return rawValue != 0
   }*/
  
  public var isEmpty: Bool {
    return rawValue != 0
  }
  
  public func has(_ options: QueryOptions) -> Bool {
    return self.intersection(options) == options
  }
  
  public static let none = QueryOptions(rawValue: 0)
  public static let caseInsensitive = QueryOptions(rawValue: 1)
  public static let diacriticInsensitive = QueryOptions(rawValue: 1 << 1)
  
}

public class ElasticQuery<A: NSManagedObject> {
  public private(set) var query: Query<A>
  public var batchSize: Int = 100
  public var results: [A] = []
  
  public required init(query: Query<A>) {
    self.query = query
  }
  
  public func loadMore() -> [A] {
    if canLoadMore {
      let batch = query
        .limit(batchSize)
        .offset(results.count)
        .execute() as [A]
      results += batch
      return batch
    } else {
      return []
    }
  }
  
  public var canLoadMore: Bool {
    return totalNumberOfResults > results.count
  }
  
  public lazy var totalNumberOfResults: Int = {
    return self.query.count()
  }()
}

public class Query<A: NSManagedObject> {
  
  public private(set) var managedObjectContext : NSManagedObjectContext
  public private(set) var fetchRequest : NSFetchRequest<NSFetchRequestResult>
  
  internal var predicates: [NSPredicate]
  
  /// Designed initializer
  ///
  /// :param entity the entity description the request should be attached to
  /// :param managedObjectContext the managedObjectContext the request should be executed against
  
  public init(_ entityName: String, context: NSManagedObjectContext = MellonStore.default.mainManagedObjectContext) {
    
    managedObjectContext = context
    fetchRequest = NSFetchRequest(entityName: entityName)
    predicates = []
    
  }
  
  public init(_ type: A.Type, context: NSManagedObjectContext = MellonStore.default.mainManagedObjectContext) {
    
    managedObjectContext = context
    fetchRequest = NSFetchRequest(entityName: type.description())
    predicates = []
    
  }
  
  public class func or(_ queries: [Query<A>]) -> Query<A> {
    let predicates = queries.map { NSCompoundPredicate(andPredicateWithSubpredicates: $0.predicates) }
    let query = Query(A.self)
    query.predicates = [NSCompoundPredicate(orPredicateWithSubpredicates: predicates)]
    return query
  }
  
  /// Shortcut accessor to execute the query as [A]
  public func all() -> [A] {
    return execute()
  }
  
  /// Shortcut accessor to execute the query as A?
  public func first() -> A? {
    /*if let primaryKey = facade_stack.config.modelPrimaryKey {
     sort("\(primaryKey) ASC")
     }*/
    return limit(1).execute()
  }
  
  /// Shortcut accessor to execute the query as A?
  public func last() -> A? {
    /*if let primaryKey = facade_stack.config.modelPrimaryKey {
     sort("\(primaryKey) DESC")
     }*/
    return limit(1).execute()
  }
  
  public func elastic() -> ElasticQuery<A> {
    return ElasticQuery(query: self)
  }
  
  /// If set to true, uniq values will be returned from the store
  /// NOTE: if set to true, the query must be executed as Dictionnary
  /// result type
  public func distinct(on: String? = nil) -> Self {
    fetchRequest.returnsDistinctResults = true
    if let on = on {
      return fetch([on as AnyObject])
    }
    return self
  }
  
  /// Use this property to set the limit of the number of objects to fetch
  public func limit(_ x: Int) -> Self {
    fetchRequest.fetchLimit = x
    return self
  }
  
  public func offset(_ x: Int) -> Self {
    fetchRequest.fetchOffset = x
    return self
  }
  
  public func fetchBatchSize(_ x: Int) -> Self {
    fetchRequest.fetchBatchSize = x
    return self
  }
  
  public func prefetch(relations: [String]) -> Self {
    fetchRequest.relationshipKeyPathsForPrefetching = relations
    return self
  }
  
  public func faults(returnsFaults: Bool) -> Self {
    fetchRequest.returnsObjectsAsFaults = returnsFaults
    return self
  }
  
  public func refresh(refreshRefetchedObjects: Bool) -> Self {
    fetchRequest.shouldRefreshRefetchedObjects = refreshRefetchedObjects
    return self
  }
  
  public func groupBy(properties: [AnyObject]) -> Self {
    fetchRequest.propertiesToGroupBy = properties
    return self
  }
  
  /// Use this property to restrict the properties of entity A to fetch
  /// from the store
  public func fetch(_ properties: [AnyObject]) -> Self {
    fetchRequest.propertiesToFetch = properties
    return self
  }
  
  public func inManagedObjectContext(managedObjectContext: NSManagedObjectContext) -> Self {
    self.managedObjectContext = managedObjectContext
    return self
  }
  
  public func toFetchedResultsController(
    sectionNameKeyPath: String? = nil,
    cacheName: String? = nil) -> NSFetchedResultsController<NSFetchRequestResult>
  {
    setPredicate()
    
    return NSFetchedResultsController(
      fetchRequest: self.fetchRequest,
      managedObjectContext: self.managedObjectContext,
      sectionNameKeyPath: sectionNameKeyPath,
      cacheName: cacheName)
  }
  
  /// Assign sorting order to the query results
  ///
  /// - parameter sortStr: The string describing the sort order of the query results
  /// (e.g: "age ASC", "age", "age ASC, id DESC")
  /// :return self
  public func sort(_ sortStr: String) -> Self {
    let components = sortStr.components(separatedBy: ",").map {
      component in component.components(separatedBy: " ")
    }
    
    fetchRequest.sortDescriptors = components.map { component in
      if component.count > 2 {
        fatalError("sort(\(sortStr)) unrecognized format")
      } else if component.count == 2 {
        return NSSortDescriptor(key: component[0], ascending: component[1] == "ASC")
      } else {
        return NSSortDescriptor(key: component[0], ascending: true)
      }
    }
    
    return self
  }
  
  /// restrict the results to objects where :key's value is contained in :objects
  ///
  /// - parameter key: the entity's property name
  /// - parameter containedIn: the values to match againsts
  /// :return: self
  public func with(_ key: String, containedIn objects: [String]) -> Self
  {
    predicates.append(
      NSPredicate(
        format: "\(key) IN %@",
        argumentArray: [objects]))
    return self
  }
  
  /// restrict the results to objects where :key's value is contained in :objects
  ///
  /// - parameter key: the entity's property name
  /// - parameter containedIn: the values to match againsts
  /// :return: self
  public func with(_ key: String, containedIn objects: [AnyObject]) -> Self
  {
    predicates.append(
      NSPredicate(
        format: "\(key) IN %@",
        argumentArray: [objects]))
    return self
  }
  
  /// restrict the results to objects where :key's value is not contained in :objects
  ///
  /// - parameter key: the entity's property name
  /// - parameter notContainedIn: the values to match againsts
  /// :return: self
  public func with(_ key: String, notContainedIn objects: [String]) -> Self {
    predicates.append(
      NSPredicate(
        format: "NOT (\(key) IN %@)",
        argumentArray: [objects]))
    return self
  }
  
  /// restrict the results to objects where :key's value is not contained in :objects
  ///
  /// - parameter key: the entity's property name
  /// - parameter notContainedIn: the values to match againsts
  /// :return: self
  public func with(_ key: String, notContainedIn objects: [AnyObject]) -> Self {
    predicates.append(
      NSPredicate(
        format: "NOT (\(key) IN %@)",
        argumentArray: [objects]))
    return self
  }
  
  /// restrict the results to objects where :key's value contains the sequence string
  ///
  /// - parameter key: the entity's property name
  /// - parameter value: the sequence to match
  /// - parameter caseSensitive: consider the search case sensitive
  /// - parameter diacriticSensitive: consider the search diacritic sensitive
  /// :return: self
  public func with(_ key: String, containing value: String, options: QueryOptions = .none) -> Self {
    let modifier = modifierFor(options)
    predicates.append(
      NSPredicate(
        format: "\(key) CONTAINS\(modifier) %@",
        argumentArray: [value]))
    return self
  }
  
  
  public func test(_ key: String, value: String) -> Self {
    var str = "SET QUOTED_IDENTIFIER ON"
    str += "GO"
    str += "SET ANSI_NULLS ON"
    str += "GO"
    
    str += "CREATE FUNCTION edit_distance_within(@s nvarchar(4000), @t nvarchar(4000), @d int)"
    str += "RETURNS int"
    str += "AS"
    str += "BEGIN"
    str += "DECLARE @sl int, @tl int, @i int, @j int, @sc nchar, @c int, @c1 int,"
    str += "@cv0 nvarchar(4000), @cv1 nvarchar(4000), @cmin int"
    str +=   "SELECT @sl = LEN(@s), @tl = LEN(@t), @cv1 = '', @j = 1, @i = 1, @c = 0"
    str +=  "WHILE @j <= @tl"
    str +=  "SELECT @cv1 = @cv1 + NCHAR(@j), @j = @j + 1"
    str +=  "WHILE @i <= @sl"
    str +=  "BEGIN"
    str +=  "SELECT @sc = SUBSTRING(@s, @i, 1), @c1 = @i, @c = @i, @cv0 = '', @j = 1, @cmin = 4000"
    str +=  "WHILE @j <= @tl"
    str +=  "BEGIN"
    str +=  "SET @c = @c + 1"
    str +=  "SET @c1 = @c1 - CASE WHEN @sc = SUBSTRING(@t, @j, 1) THEN 1 ELSE 0 END"
    str +=  "IF @c > @c1 SET @c = @c1"
    str +=   "SET @c1 = UNICODE(SUBSTRING(@cv1, @j, 1)) + 1"
    str +=   "IF @c > @c1 SET @c = @c1"
    str +=  "IF @c < @cmin SET @cmin = @c"
    str += "SELECT @cv0 = @cv0 + NCHAR(@c), @j = @j + 1"
    str +=  "END"
    str +=  "IF @cmin > @d BREAK"
    str +=  "SELECT @cv1 = @cv0, @i = @i + 1"
    str += "END"
    str += "RETURN CASE WHEN @cmin <= @d AND @c <= @d THEN @c ELSE -1 END"
    str +=  "END"
    str +=  "GO"
    
    predicates.append(
      NSPredicate(
        format: "\(str)\n\n edit_distance_within(\(key),%@) <= 5",
        argumentArray: [value]))
    
    return self
    
  }
  
  /// restrict the results to objects where :key's value is LIKE the given pattern
  ///
  /// - parameter key: the entity's property name
  /// - parameter LIKE: pattern
  /// - parameter caseSensitive: consider the search case sensitive
  /// - parameter diacriticSensitive: consider the search diacritic sensitive
  /// :return: self
  public func with(_ key: String, like value: String, options: QueryOptions = .none) -> Self {
    let modifier = modifierFor(options)
    predicates.append(
      NSPredicate(
        format: "\(key) LIKE\(modifier) %@",
        argumentArray: [value]))
    return self
  }
  
  /// restrict the results to objects where :key's set/array contains all the given values
  ///
  /// - parameter key: the entity's property name
  /// - parameter values: the values the entity's set/array must contain
  /// :return: self
  public func with(_ key: String, containingAll values: [AnyObject]) -> Self {
    predicates.append(
      NSPredicate(
        format: "ALL \(key) IN %@",
        argumentArray: [values]))
    return self
  }
  
  /// restrict the results to objects where :key's set/array contains none of the given values
  ///
  /// - parameter key: the entity's property name
  /// - parameter values: the values the entity's set/array must not contain
  /// :return: self
  public func with(_ key: String, containingNone values: [AnyObject]) -> Self {
    predicates.append(
      NSPredicate(
        format: "NONE \(key) IN %@",
        argumentArray: [values]))
    return self
  }
  
  /// restrict the results to objects where :key's set/array contains any of the given values
  ///
  /// - parameter key: the entity's property name
  /// - parameter values: the values the entity's set/array can contain
  /// :return: self
  public func with(_ key: String, containingAny values: [AnyObject]) -> Self {
    predicates.append(
      NSPredicate(
        format: "ANY \(key) IN %@",
        argumentArray: [values]))
    return self
  }
  
  /// restrict the results to objects where :key's must exist or not
  ///
  /// - parameter key: the entity's property name
  /// - parameter exists: true if the key must exists, false otherwise
  /// :return: self
  public func with(_ key: String, existing exists: Bool) -> Self {
    let matcher = exists ? "!=" : "=="
    predicates.append(
      NSPredicate(
        format: "\(key) \(matcher) NIL"))
    return self
  }
  
  /// restrict the results to objects where :key's must have the given suffix
  ///
  /// - parameter key: the entity's property name
  /// - parameter endingWith: the suffix
  /// - parameter caseSensitive: consider the search case sensitive
  /// - parameter diacriticSensitive: consider the search diacritic sensitive
  /// :return: self
  public func with(_ key: String, endingWith suffix: String, options: QueryOptions = .none) -> Self {
    let modifier = modifierFor(options)
    predicates.append(
      NSPredicate(
        format: "\(key) ENDSWITH\(modifier) %@",
        argumentArray: [suffix]))
    return self
  }
  
  /// restrict the results to objects where :key's must have the given prefix
  ///
  /// - parameter key: the entity's property name
  /// - parameter startingWith: the prefix
  /// - parameter caseSensitive: consider the search case sensitive
  /// - parameter diacriticSensitive: consider the search diacritic sensitive
  /// :return: self
  public func with(_ key: String, startingWith prefix: String, options: QueryOptions = .none) -> Self {
    let modifier = modifierFor(options)
    predicates.append(
      NSPredicate(
        format: "\(key) BEGINSWITH\(modifier) %@",
        argumentArray: [prefix]))
    return self
  }
  
  /// restrict the results to objects where :key's must be equal to the given value
  ///
  /// - parameter key: the entity's property name
  /// - parameter equalTo: the value
  /// - parameter caseSensitive: consider the search case sensitive
  /// - parameter diacriticSensitive: consider the search diacritic sensitive
  /// :return: self
  public func with(_ key: String, equalTo value: String?, options: QueryOptions = .none) -> Self {
    guard value != nil else {
      return with(key, existing: false)
    }
    
    var modifier = modifierFor(options)
    if modifier == "" {
      modifier = "="
    }
    predicates.append(
      NSPredicate(
        format: "\(key) =\(modifier) %@",
        argumentArray: [value!]))
    return self
  }
  
  /// restrict the results to objects where :key's must be equal to the given value
  ///
  /// - parameter key: the entity's property name
  /// - parameter equalTo: the value
  /// - parameter caseSensitive: consider the search case sensitive
  /// - parameter diacriticSensitive: consider the search diacritic sensitive
  /// :return: self
  public func with(_ key: String, equalTo value: AnyObject?, options: QueryOptions = .none) -> Self {
    guard value != nil else {
      return with(key, existing: false)
    }
    
    var modifier = modifierFor(options)
    if modifier == "" {
      modifier = "="
    }
    predicates.append(
      NSPredicate(
        format: "\(key) =\(modifier) %@",
        argumentArray: [value!]))
    return self
  }
  
  /// restrict the results to objects where :key's must not be equal to the given value
  ///
  /// - parameter key: the entity's property name
  /// - parameter equalTo: the value
  /// - parameter caseSensitive: consider the search case sensitive
  /// - parameter diacriticSensitive: consider the search diacritic sensitive
  /// :return: self
  public func with(_ key: String, notEqualTo value: String?, options: QueryOptions = .none) -> Self {
    guard value != nil else {
      return with(key, existing: true)
    }
    
    let modifier = modifierFor(options)
    predicates.append(
      NSPredicate(
        format: "\(key) !=\(modifier) %@",
        argumentArray: [value ?? "NIL"]))
    return self
  }
  
  
  /// restrict the results to objects where :key's must not be equal to the given value
  ///
  /// - parameter key: the entity's property name
  /// - parameter equalTo: the value
  /// - parameter caseSensitive: consider the search case sensitive
  /// - parameter diacriticSensitive: consider the search diacritic sensitive
  /// :return: self
  public func with(_ key: String, notEqualTo value: AnyObject?, options: QueryOptions = .none) -> Self {
    guard value != nil else {
      return with(key, existing: true)
    }
    
    let modifier = modifierFor(options)
    predicates.append(
      NSPredicate(
        format: "\(key) !=\(modifier) %@",
        argumentArray: [value ?? "NIL"]))
    return self
  }
  
  /// restrict the results to objects where :key's must not be greater than the value
  ///
  /// - parameter key: the entity's property name
  /// - parameter greaterThan: the value
  /// :return: self
  public func with(_ key: String, greaterThan value: Double) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) > %@",
        argumentArray: [value]))
    return self
  }
  
  /// restrict the results to objects where :key's must not be greater than or equal the value
  ///
  /// - parameter key: the entity's property name
  /// - parameter greaterThanOrEqual: the value
  /// :return: self
  public func with(_ key: String, greaterThanOrEqual value: Double) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) >= %@",
        argumentArray: [value]))
    return self
  }
  
  public func with(_ key: String, greaterThanOrEqual value: Date) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) >= %@",
        argumentArray: [value]))
    return self
  }
  
  
  /// restrict the results to objects where :key's must not be greater than the value
  ///
  /// - parameter key: the entity's property name
  /// - parameter greaterThan: the value
  /// :return: self
  public func with(_ key: String, greaterThan value: Int) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) > %@",
        argumentArray: [value]))
    return self
  }
  
  public func with(_ key: String, greaterThan value: Date) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) > %@",
        argumentArray: [value]))
    return self
  }
  
  
  /// restrict the results to objects where :key's must not be greater than or equal the value
  ///
  /// - parameter key: the entity's property name
  /// - parameter greaterThanOrEqual: the value
  /// :return: self
  public func with(_ key: String, greaterThanOrEqual value: Int) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) >= %@",
        argumentArray: [value]))
    return self
  }
  
  /// restrict the results to objects where :key's must not be lower than the value
  ///
  /// - parameter key: the entity's property name
  /// - parameter lowerThan: the value
  /// :return: self
  public func with(_ key: String, lowerThan value: Double) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) < %@",
        argumentArray: [value]))
    return self
  }
  
  /// restrict the results to objects where :key's must not be lower than or equal the value
  ///
  /// - parameter key: the entity's property name
  /// - parameter lowerThanOrEqual: the value
  /// :return: self
  public func with(_ key: String, lowerThanOrEqual value: Double) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) <= %@",
        argumentArray: [value]))
    return self
  }
  
  /// restrict the results to objects where :key's must not be lower than the value
  ///
  /// - parameter key: the entity's property name
  /// - parameter lowerThan: the value
  /// :return: self
  public func with(_ key: String, lowerThan value: Int) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) < %@",
        argumentArray: [value]))
    return self
  }
  
  public func with(_ key: String, lowerThan value: Date) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) < %@",
        argumentArray: [value]))
    return self
  }
  
  
  /// restrict the results to objects where :key's must not be lower than or equal the value
  ///
  /// - parameter key: the entity's property name
  /// - parameter lowerThanOrEqual: the value
  /// :return: self
  public func with(_ key: String, lowerThanOrEqual value: Int) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) <= %@",
        argumentArray: [value]))
    return self
  }
  
  public func with(_ key: String, lowerThanOrEqual value: Date) -> Self {
    predicates.append(
      NSPredicate(
        format: "\(key) <= %@",
        argumentArray: [value]))
    return self
  }
  
  /// Execute the fetch request as a count operation
  ///
  /// :return: the number of objects matching against query
  public func count() -> Int {
    setPredicate()
    
    fetchRequest.includesSubentities = false
    
    var count: Int!
    
    managedObjectContext.performAndWait {
      do {
        count = try self.managedObjectContext.count(for: self.fetchRequest)
      } catch let error as NSError {
        _ = self.shouldHandleError(error)
      }
    }
    
    return count
  }
  
  public func delete() {
    setPredicate()
    
    // We do not need to load any values
    fetchRequest.includesPropertyValues = false
    
    managedObjectContext.performAndWait {
      for object in self.execute() as [A] {
        self.managedObjectContext.delete(object)
      }
    }
  }
  
  @available(iOS 9.0, *)
  public func batchDelete() {
    setPredicate()
    
    let batchRequest = NSBatchDeleteRequest(fetchRequest: self.fetchRequest)
    
    managedObjectContext.performAndWait {
      do {
        try self.managedObjectContext.execute(batchRequest)
      } catch let error as NSError {
        if self.shouldHandleError(error) {
          print("Error executing batch deleted request: \(batchRequest), fetchRequest: \(self.fetchRequest) Error: \(error)")
        }
      }
    }
  }
  
  /// Execute the fetch request and return its first optional object
  /// :return: optional object
  public func execute() -> A? {
    return execute().first
  }
  
  /// Execute the fetch request and return its objects
  /// :return: [objects]
  public func execute() -> [A] {
    fetchRequest.resultType = .managedObjectResultType
    return _execute() as! [A]
  }
  
  /// Execute the fetch request as Dictionnaries return type
  /// and return the first optional dictionnary
  /// :return: NSDictionary
  public func execute() -> NSDictionary? {
    return execute().first
  }
  
  /// Execute the fetch request as Dictionnaries return type
  /// :return: [NSDictionary]
  public func execute() -> [NSDictionary] {
    fetchRequest.resultType = .dictionaryResultType
    return _execute() as! [NSDictionary]
  }
  
  /// Execute the fetch request as NSManagedObjectID return type
  /// :return: [NSManagedObjectID]
  public func execute() -> [NSManagedObjectID] {
    fetchRequest.resultType = .managedObjectIDResultType
    return _execute() as! [NSManagedObjectID]
  }
  
  private func _execute() -> [AnyObject]? {
    setPredicate()
    
    var objects: [AnyObject]?
    managedObjectContext.performAndWait {
      do {
        objects = try self.managedObjectContext.fetch(
          self.fetchRequest)
        self.log()
      } catch let error as NSError {
        if self.shouldHandleError(error) {
          print("Error executing fetchRequest: \(self.fetchRequest). Error: \(error)")
        }
        objects = []
      }
    }
    
    return objects
  }
  
  private func setPredicate() {
    if !predicates.isEmpty {
      fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    } else {
      fetchRequest.predicate = nil
    }
  }
  
  private func modifierFor(_ options: QueryOptions) -> String {
    let modifiers = [(options.has(.caseInsensitive), "c"), (options.has(.diacriticInsensitive), "d")]
    let activeModifiers = modifiers.filter { $0.0 }.map { $0.1 }.joined(separator: "")
    return activeModifiers.characters.count > 0 ? "[\(activeModifiers)]" : ""
  }
  
  private func shouldHandleError(_ error: NSError?) -> Bool {
    if error == nil {
      return false
    }
    // @TODO: Do some error handling via event system
    print("Error executing fetchRequest: \(fetchRequest). Error: \(String(describing: error))")
    return true
  }
}
