#ZObject

`ZObject` is an experimental project for me to work on large object data on Apple platform with Swift programmming language.  It is based on Sqlite3 database, and all `ZObject` based objects are lived in sqlute3 database to load and to save.

When a `ZObject` instances are created, a unique object identifier will be assigned to that object.  This identifier will be the primary key to load and to save on sqlite database.  Since, `ZObject` is based on `NSObject`, you may write encode and decode itself just like  any other `NSObject` subclasses.  Here is the example of `ZObject` subclass `Rectangle`.


```.swift
protocol Shape: ZObject {
}

class Rectangle: ZObject, Shape {
	var origin: CGPoint
	var size: CGSize
	enum Keys: String { case origin, size }
	init(origin: CGPoint, size: CGSize, storage: ZStorage) throws {
		self.origin = origin
		self.size = size
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(self.origin, forKey: Self.Keys.origin.rawValue)
		coder.encode(self.size, forKey: Self.Keys.size.rawValue)
	}
	required init?(coder: NSCoder) {
		self.origin = coder.decodeCGPoint(forKey: Self.Keys.origin.rawValue)
		self.size = coder.decodeCGSize(forKey: Self.Keys.size.rawValue)
		super.init(coder: coder)
	}
	override var description: String {
		return "{\(Self.self): origin=\(self.origin), size=\(size)}"
	}
}
```

In this example, there is an interesting initializer that requires storage parameter.  `ZStorage` represents sqlite3 database file to save and to load those `Zobject`.  Here is an example code to create `Rectangle` object and save it to `ZStorage`.

```.swift
do {
    let storage = try ZStorage(fileURL: ...)
    let rectangle = try Rectangle(origin: CGPoint(x: 101, y: 102), size: CGSize(width: 103, height: 104), storage: storage)
    try rectangle(storage: storage)
}
catch {...}
```

Then, when you want to load all `Rectangle` object, use `instanciateObjects(of:)` method to instantiate them.

```.swift
if let rectangles = try storage.instanciateObjects(of: Rectangle) {
	for rectangle in rectangles {
		// do something here of `rectangle`
	}
}
```

## Archiving Objecting Graph

One interesting feature about `ZObject` is to design object relationship just like other `NSObject` subclasses.  Say, here is the object model as `ZObject` subclasses.  `Rectangle` and `Circle` are based on `Shape` protocol. A `Layer` contains those `Shape`s, A `Page` contains `Layer`s, and A `Container` contains `Page`s.

```.swift
class Circle: ZObject, Shape {
	var center: CGPoint
	var radius: CGFloat
	enum Keys: String { case center, radius }
	init(center: CGPoint, radius: CGFloat, storage: ZStorage) throws {
		self.center = center
		self.radius = radius
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(self.center, forKey: Self.Keys.center.rawValue)
		coder.encode(self.radius, forKey: Self.Keys.radius.rawValue)
	}
	required init?(coder: NSCoder) {
		self.center = coder.decodeCGPoint(forKey: Self.Keys.center.rawValue)
		self.radius = coder.decodeObject(forKey: Self.Keys.radius.rawValue) as! CGFloat
		super.init(coder: coder)
	}
	override var description: String {
		return "{\(Self.self): center=\(self.center), radius=\(radius)}"
	}
}

class Layer: ZObject {
	var shapes: [Shape]
	static let shapesKey = "shapes"
	init(shapes: [Shape], storage: ZStorage) throws {
		self.shapes = shapes
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		coder.encode(shapes, forKey: Self.shapesKey)
		super.encode(with: coder)
	}
	required init?(coder: NSCoder) {
		self.shapes = coder.decodeObject(forKey: Self.shapesKey) as! [Shape]
		super.init(coder: coder)
	}
}

class Page: ZObject {
	var layers: [Layer]
	static let layersKey = "layers"
	init(layers: [Layer], storage: ZStorage) throws {
		self.layers = layers
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		coder.encode(layers, forKey: Self.layersKey)
		super.encode(with: coder)
	}
	required init?(coder: NSCoder) {
		self.layers = coder.decodeObject(forKey: Self.layersKey) as! [Layer]
		super.init(coder: coder)
	}
}

class Contents: ZObject {
	var pages: [Page]
	static let pagesKey = "pages"
	init(pages: [Page], storage: ZStorage) throws {
		self.pages = pages
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		coder.encode(pages, forKey: Self.pagesKey)
		super.encode(with: coder)
	}
	required init?(coder: NSCoder) {
		self.pages = coder.decodeObject(forKey: Self.pagesKey) as! [Page]
		super.init(coder: coder)
	}
}
```

By writing following code, all object graph from `Contents` to `Shape` can be saved and restored as easy as pie.

```.swift
do {
    let storage = try ZStorage(fileURL: ...)
    let c1 = try Circle(center: CGPoint(x: 100, y: 200), radius: 300, storage: storage)
    let r1 = try Rectangle(origin: CGPoint(x: 101, y: 102), size: CGSize(width: 103, height: 104), storage: storage)
    let layer1 = try Layer(shapes: [c1, r1], storage: storage)
    
    let c2 = try Circle(center: CGPoint(x: 400, y: 500), radius: 600, storage: storage)
    let r2 = try Rectangle(origin: CGPoint(x: 201, y: 202), size: CGSize(width: 203, height: 204), storage: storage)
    let layer2 = try Layer(shapes: [c2, r2], storage: storage)
    let page1 = try Page(layers: [layer1, layer2], storage: storage)
    
    let c3 = try Circle(center: CGPoint(x: 700, y: 800), radius: 900, storage: storage)
    let layer3 = try Layer(shapes: [c3], storage: storage)
    let page2 = try Page(layers: [layer3], storage: storage)
    
    let contents = try Contents(pages: [page1, page2], storage: storage)
    try contents.save(storage: storage)
}
catch {...}
```

```.swift
do {
    let storage = try ZStorage(fileURL: ...)
    let contents = try storage.instanciateObjects(of: Contents.self)
}
catch {...}
```

The beauty of this project is that you do not need to complex code to load and to save complex object relationship.  Your `ZObject` subclass only responsible to provide initializer with `Storage` object, and `NSCoding` methods.


## TO DO

I was experimenting this project to solve one particular issue on my side project, but I think I found an easier way to archive the issue, so I may stop working on this project for a while.  However, here is the wish list for the next step.

I don't know much about Realm solution, I feel like when I work more and more, this project may be closer and closer to Realm.

### Automatic Reference Count

Just like `NSObject` on memory base, I like `ZObject` can provide `retain` and `release` lifecycle.  So you don't have to take extra consideration when to delete from the database.

```.swift
// initially...
ler storage: ZStorage = ...
let c1: Circle = ...
let r1: Rectangle = ...
let layer = try Layer(shapes: [c1, r1], storage: storage)

// later on ...
let c2: Circle = ...
let r2: Rectangle = ...
layer.shapes = [c2, r1]
// c1, r1 to be deleted from database when necessary
```
In order to achieve this, it has to manage and maintain loaded / unloaded objects in the database.  It is challenging, but it may be possible by taking advantage from `Mirror(reflecting:)`.

### Keyword Referenced Object

In some cases, you may like to access main / root object, rather than list of all objects of the same type.  Say, provide some API look like...

```.swift
let storage: ZStorage = ...
if let contents = storage.object(for: "main") {
	...
}
``` 

## License

MIT
