//
//  MellonStoreTests.swift
//  MellonStoreTests
//
//  Created by favre on 28/07/2018.
//  Copyright © 2018 mellonmellon. All rights reserved.
//

import XCTest
@testable import MellonStore

class MellonStoreTests: XCTestCase {
  
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
  
  func testInsert() {
    let uuidString = UUID().uuidString
    let fruit = Query(Fruit.self).with("id", equalTo: uuidString).first()
    XCTAssertNil(fruit)
    
    MellonStore.default.transaction { context in
      do {
        let fruit = try Fruit.create(in: context)
        fruit.id = uuidString
        fruit.name = "mellon"
      } catch let error {
        print(error.localizedDescription)
      }
    }
    
    let newFruit = Query(Fruit.self).with("id", equalTo: uuidString).first()
    XCTAssertNotNil(newFruit)
    XCTAssertEqual(newFruit?.name, "mellon")
    
  }
}
