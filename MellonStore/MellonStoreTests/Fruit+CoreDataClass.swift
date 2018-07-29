//
//  Fruit+CoreDataClass.swift
//  MellonStore
//
//  Created by favre on 28/07/2018.
//  Copyright © 2018 mellonmellon. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Fruit)
public class Fruit: NSManagedObject {

  @NSManaged public var id: String?
  @NSManaged public var name: String?
}
