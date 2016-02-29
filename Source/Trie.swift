// Trie.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2016 Dan Appel
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

public struct Trie<Element: Comparable, Payload> {
    let prefix: Element?
    var payload: Payload?
    var ending: Bool
    var children: [Trie<Element, Payload>]
    
    init() {
        self.prefix = nil
        self.payload = nil
        self.ending = false
        self.children = []
    }
    
    init(prefix: Element, payload: Payload?, ending: Bool, children: [Trie<Element, Payload>]) {
        self.prefix = prefix
        self.payload = payload
        self.ending = ending
        self.children = children
        self.children.sortInPlace()
    }
}

public func ==<Element, Payload where Element: Comparable>(lhs: Trie<Element, Payload>, rhs: Trie<Element, Payload>) -> Bool {
    return lhs.prefix == rhs.prefix
}

public func <<Element, Payload where Element: Comparable>(lhs: Trie<Element, Payload>, rhs: Trie<Element, Payload>) -> Bool {
    return lhs.prefix < rhs.prefix
}

extension Trie: Comparable { }

extension Trie {
    
    var description: String {
        return pretty(depth: 0)
    }
    
    func pretty(depth depth: Int) -> String {
        
        let key: String
        if let k = self.prefix {
            key = "\(k)"
        } else {
            key = "head"
        }
        
        let payload: String
        if let p = self.payload {
            payload = ":\(p)"
        } else {
            payload = ""
        }
        
        let children = self.children
            .map { $0.pretty(depth: depth + 1) }
            .reduce("", combine: +)
        
        let pretty = "- \(key)\(payload)" + "\n" + "\(children)"
        
        let indentation = (0..<depth).reduce("", combine: {$0.0 + "  "})
        
        return "\(indentation)\(pretty)"
    }
}

extension Trie {
    mutating func insert<Sequence: SequenceType where Sequence.Generator.Element == Element>(sequence: Sequence, payload: Payload? = nil) {
        insert(sequence.generate(), payload: payload)
    }
    
    mutating func insert<Generator: GeneratorType where Generator.Element == Element>(generator: Generator, payload: Payload? = nil) {
        
        var generator = generator
        
        guard let element = generator.next() else {
            self.payload = self.payload ?? payload
            self.ending = true
            
            return
        }
        
        for (index, child) in children.enumerate() {
            var child = child
            if child.prefix == element {
                child.insert(generator, payload: payload)
                self.children[index] = child
                self.children.sortInPlace()
                return
            }
        }
        
        var new = Trie<Element, Payload>(prefix: element, payload: nil, ending: false, children: [])
        
        new.insert(generator, payload: payload)
        
        self.children.append(new)

        self.children.sortInPlace()
    }
}

extension Trie {
    func findLast<Sequence: SequenceType where Sequence.Generator.Element == Element>(sequence: Sequence) -> Trie<Element, Payload>? {
        return findLast(sequence.generate())
    }
    
    func findLast<Generator: GeneratorType where Generator.Element == Element>(generator: Generator) -> Trie<Element, Payload>? {
        
        var generator = generator
        
        guard let target = generator.next() else {
            guard ending == true else { return nil }
            return self
        }

        // binary search
        var lower = 0
        var higher = children.count - 1

        while (lower <= higher) {
            let middle = (lower + higher) / 2
            let child = children[middle]
            guard let current = child.prefix else { continue }

            if (current == target) {
                return child.findLast(generator)
            }

            if (current < target) {
                lower = middle + 1
            }

            if (current > target) {
                higher = middle - 1
            }
        }
        
        return nil
    }
}

extension Trie {
    func findPayload<Sequence: SequenceType where Sequence.Generator.Element == Element>(sequence: Sequence) -> Payload? {
        return findPayload(sequence.generate())
    }
    func findPayload<Generator: GeneratorType where Generator.Element == Element>(generator: Generator) -> Payload? {
        return findLast(generator)?.payload
    }
}

extension Trie {
    func contains<Sequence: SequenceType where Sequence.Generator.Element == Element>(sequence: Sequence) -> Bool {
        return contains(sequence.generate())
    }
    
    func contains<Generator: GeneratorType where Generator.Element == Element>(generator: Generator) -> Bool {
        return findLast(generator) != nil
    }
}

extension Trie where Payload: Equatable {
    func findByPayload(payload: Payload) -> [Element]? {
        
        if self.payload == payload {
            // not sure what to do if it doesnt have a prefix
            if let prefix = self.prefix {
                return [prefix]
            }
            return []
        }
        
        for child in children {
            if let prefixes = child.findByPayload(payload) {
                if let prefix = self.prefix {
                    return [prefix] + prefixes
                }
                return prefixes
            }
        }
        return nil
    }
}

extension Trie {
    mutating func sort(isOrderedBefore: (Trie<Element, Payload>, Trie<Element, Payload>) -> Bool) {
        self.children = children.map { child in
            var child = child
            child.sort(isOrderedBefore)
            return child
        }

        self.children.sortInPlace(isOrderedBefore)
    }
}
