//
//  MellonStoreSwitchTests.swift
//  MellonStoreTests
//
//  Created by favre on 29/07/2018.
//  Copyright © 2018 mellonmellon. All rights reserved.
//

import XCTest
import CoreData

class MellonStoreManipulationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
      MellonStore.modelName = "Mellon"
      MellonStore.setup(storeName: "Mellon_switch_test", inMemory: false)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStoreManipulation() {
       var ids: [String] = []
      
      //Create
      MellonStore.default.transaction { context in
        for _ in 0...5 {
          let uuid = self.create(withName: self.generateRandomName(), in: context)
          print("create fruit with uuid: \(uuid)")
          if !uuid.isEmpty { ids.append(uuid) }
        }
      }
      let fruits = Query(Fruit.self).with("id", containedIn: ids).all()
      XCTAssertEqual(fruits.count, ids.count)
      
      //Swith
      MellonStore.switchTo(storeIdentifier: "otherStore_switch_test")
      
      let otherStoreFruit = Query(Fruit.self).with("id", containedIn: ids).all()
      XCTAssertEqual(otherStoreFruit.count, 0)
      
      //Re-switch
      MellonStore.switchTo(storeIdentifier: "Mellon_switch_test")
      let mainFruits = Query(Fruit.self).with("id", containedIn: ids).all()
      XCTAssertEqual(mainFruits.count, ids.count)
      
      try? MellonStore.deleteStore(for: "Mellon_copy_test") //delete if already exist
      try! MellonStore.default.copyStore(for: "Mellon_copy_test")
      MellonStore.switchTo(storeIdentifier: "Mellon_copy_test")
      
      let copyFruits = Query(Fruit.self).with("id", containedIn: ids).all()
      XCTAssertEqual(copyFruits.count, ids.count)
      
      // Delete
      try! MellonStore.deleteStore(for: "Mellon_copy_test")
    }
}
