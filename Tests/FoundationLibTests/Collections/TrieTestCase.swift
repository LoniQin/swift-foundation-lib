
//
//  TrieTestCase.swift
//
//
//  Created by lonnie on 2020/10/17.
//

import Foundation
import XCTest
@testable import FoundationLib
final class TrieTestCase: XCTestCase {

    func testTrie() throws {
        let trie = Trie<Character, Void>(.lowercasedAlphabets)
        try DebugLogger.default.measure {
            for _ in 0..<10000 {
                let word = Array(count: 10, in: .lowercasedAlphabets)
                try trie.insert(word)
                try trie.search(word).assert.equal(true)
                try trie.startsWith(word).assert.equal(true)
                
            }
        }
    }
    
    func testTrie2() throws {
        let trie = Trie<Character, Int>(.numbers)
        try DebugLogger.default.measure(description: "Insert number with Trie") {
            for i in 0..<100000 {
                let key = i.description.map({$0})
                try trie.insert(key, i)
                try trie.value(key).assert.equal(i)
            }
        }
        var dic: [String: Int] = [:]
        try DebugLogger.default.measure(description: "Insert number with Dictionary") {
            for i in 0..<100000 {
                dic[i.description] = i
                dic[i.description].assert.equal(i)
            }
        }
        
        let redBlackTree = RedBlackTree<String, Int>()
        try DebugLogger.default.measure(description: "Insert number with RebBlackTree") {
            for i in 0..<100000 {
                redBlackTree[i.description] = i
                redBlackTree[i.description].assert.equal(i)
            }
        }
        
        
        let trie2 = Trie<Character, Int>(.numbers)
        let key = "12345".map({$0})
        trie2[key] = 12345
        trie2[key].assert.equal(12345)
        trie2[key] = 89893
        trie2[key].assert.equal(89893)
    }
}
