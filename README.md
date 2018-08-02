# MellonStore
100% swift. thread safe, easy writing and reading operation.

---

## How it work

![Screenshot](https://github.com/MellonMellon/MellonStore/blob/master/figure-concurrency-basics.jpg)

As you can see, there is three kind of NSManagedObjectContext.

### private managed object context

The private managed object context is a background context and it's linked to the persistent store coordinator. 
Data is written locally hhen the private managed object context save it changes.

It have one child which is the main managed object context.

### main managed object context

Child of the private managed object context. Associate to the main thread, it is use for reading operation.

### child managed object context

When you need to perform write, update or delete operations, it is a best practice to use a new context used for those operations.

A child managed object context is create with transaction method. When an operation is done, the child is merged into the main managed object context.

---

## Table of Contents

- [Installation](#installation)
- [Features](#features)
- [License](#license)

---

## Example

```swift
 //prepare Mellon Store
 MellonStore.modelName = "ModelName"
 MellonStore.setup() // can be async
      
 // create a fruit
 MellonStore.default.transaction { context in
    let fruit = try? Fruit.create(in: context)
    fruit?.name = name
 }
 
 // get all fruits
 let fruits = Query(Fruit.self).all()
    
```

---

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate MellonStore into your Xcode project using CocoaPods, it in your `Podfile`:

```ruby
platform :ios, '9.0'
use_frameworks!

source "https://github.com/MellonMellon/Specs.git"

target '<Your Target Name>' do
  pod 'MellonStore'
end
```

Then, run the following command:

```bash
$ pod install
```

## Features

### Write

transaction method create a background context that you can use for creating, udpating and/or deleting operation.
```swift
MellonStore.default.transaction { context in
    let fruit = try? Fruit.create(in: context)
    fruit?.name = name
 }
```

Or, you can create a new context and use it.

```swift
let backgroundContext = MellonStore.default.newBackgroundContext()
let fruit = try? Fruit.create(in: context)
fruit?.name = name
try! backgroundContext.save()
```

### Read

#### read all

```swift
let fruits = Query(Fruit.self).all()
```

#### read only a single fruit
```swift
let fruit = Query(Fruit.self).first() // return a single fruit: Fruit
```

#### filter

Chain your filter condition using `with`
```swift
let fruits = Query(Fruit.self)
      .with("name", equalTo: "banana")
      .with("name", like: "banana")
      .with("name", existing: true)
      .with("name", containing: "ban")
      .with("created", lowerThan: Date())
      .with("created", greaterThan: Date())
      .with("created", lowerThanOrEqual: Date())
      .with("name", containedIn: ["banana", "coconut"])
      .with("name", startingWith: "ban")
      .with("name", endingWith: "na")
      .all()   // return an array: [Fruit]
```

#### Elastic
```swift
let elasticSearch = Query(Fruit.self).elastic()
let total = elasticSearch.totalNumberOfResults

let allFruits: [Fruit] = []

while elasticSearch.canLoadMore {
  let fruits = elasticSearch.loadMore()
  allFruits.append(fruits)
}
```


#### sort
```swift
let fruits = Query(Fruit.self).sort("name")
```

### Switch
```swift
MellonStore.setup(storeName: "another_store")
```
### Copy
```swift
MellonStore.default.copyStore(for: "new_storage")
```

### Delete
```swift
MellonStore.deleteStore(for: "storage_identifier")
```

---
## License

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

- **[MIT license](http://opensource.org/licenses/mit-license.php)**
