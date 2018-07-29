//
//  Util.swift
//  MellonStoreTests
//
//  Created by favre on 29/07/2018.
//  Copyright © 2018 mellonmellon. All rights reserved.
//

import XCTest
import CoreData
@testable import MellonStore

extension XCTestCase {
  
  public func create(withName name: String, in context: NSManagedObjectContext) -> String{
    do {
      let uuidString = UUID().uuidString
      let fruit = try Fruit.create(in: context)
      fruit.id = uuidString
      fruit.name = name
      return uuidString
    } catch let error {
      print(error.localizedDescription)
      XCTFail(error.localizedDescription)
    }
    return ""
  }
  
  public func generateRandomName() -> String {
    let array = ["Banana", "Cherry", "Apple", "Blackberry", "Blueberry", "Coconut", "Raspberry", "Strawberry"]
    let randomIndex = Int(arc4random_uniform(UInt32(array.count)))
    return array[randomIndex]
  }
}
