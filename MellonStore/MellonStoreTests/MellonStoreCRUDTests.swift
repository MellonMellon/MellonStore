//
//  MellonStoreTests.swift
//  MellonStoreTests
//
//  Created by favre on 28/07/2018.
//  Copyright © 2018 mellonmellon. All rights reserved.
//

import XCTest
import CoreData
@testable import MellonStore

class MellonStoreCRUDTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    MellonStore.modelName = "Mellon"
    MellonStore.setup(inMemory: true)
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  /*private func create(withName name: String, in context: NSManagedObjectContext) -> String{
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
  
  func generateRandomName() -> String {
    let array = ["Banana", "Cherry", "Apple", "Blackberry", "Blueberry", "Coconut", "Raspberry", "Strawberry"]
    let randomIndex = Int(arc4random_uniform(UInt32(array.count)))
    return array[randomIndex]
  }*/
  
  func testCRUD() {
    var ids: [String] = []
    
    //CREATE
    
    MellonStore.default.transaction { [unowned self] context in
      for _ in 0...5 {
        let uuid = self.create(withName: self.generateRandomName(), in: context)
        print("create fruit with uuid: \(uuid)")
        if !uuid.isEmpty {
          ids.append(uuid)
        }
      }
    }
    
    let fruits = Query(Fruit.self).with("id", containedIn: ids).all()
    XCTAssertEqual(fruits.count, ids.count)
    
    //UPDATE
    
    let fruit = fruits.first!
    let id = fruit.id!
    MellonStore.default.transaction { context in
      let fruitsToUpdate = context.fetch(entity: fruit)
      fruitsToUpdate.name = "MELLON"
    }
    
    let mellonFruit = Query(Fruit.self).with("id", equalTo: id).first()
    XCTAssertNotNil(mellonFruit)
    XCTAssertEqual(mellonFruit!.name, "MELLON")
    
    //DELETE
    MellonStore.default.transaction { context in
      Query(Fruit.self, context: context)
        .with("id", notEqualTo: id)
        .with("id", containedIn: ids)
        .delete()
    }
    
    let newFruits = Query(Fruit.self).with("id", containedIn: ids).all()
    XCTAssertEqual(newFruits.count, 1)
    XCTAssertNotNil(newFruits.first)
    XCTAssertEqual(newFruits.first!.name, "MELLON")
  }
}
