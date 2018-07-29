//
//  Query+Logger.swift
//  Boardnox
//
//  Created by Thomas Favre on 27/09/2017.
//  Copyright © 2017 Oodrive. All rights reserved.
//

import Foundation

extension Query {

	public func log() {
    #if DEBUG
		print("[📣] SELECT \(fetchRequest.entityName ?? "??") WHERE \(fetchRequest.predicate?.description ?? "??") SORT \(String(describing: fetchRequest.sortDescriptors))")
		print("\n")
    #endif
	}
}
