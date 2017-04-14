//
//  EmojiParser.swift
//  Pods
//
//  Created by Maxime Bertheau on 4/12/17.
//
//

import Foundation

open class EmojiParser {
  
  fileprivate static let emojiManager = EmojiManager()

  open static func getAliasesFromUnicode(_ unicode: String) -> [String] {
    
    guard let leaf = emojiManager.getLeafForBytes(bytes: [UInt8](unicode.utf8)) else { return [] }
    
    return leaf.emojis.map { $0.shortName }
  }
  
  open static func getUnicodeFromAlias(_ alias: String) -> String? {
    
    do {
    
    let input = alias as NSString
    
    let aliasMatchingRegex = try NSRegularExpression(pattern: ":?([\\w_+-]+)(?:(?:\\||::)(type_[\\w_]*))?:?", options: .caseInsensitive)
    
    let matches = aliasMatchingRegex.matches(in: alias, options: .withoutAnchoringBounds, range: NSRange(location: 0, length: alias.characters.count))
    
    if(matches.count == 0) {
      return input as String!
    }
    
    let match = matches[0]
    
    let alias = input.substring(with: match.rangeAt(1))
    
    var skinVariationString: String?
    let skinVariationLocation = match.rangeAt(2)
    
    if skinVariationLocation.location + skinVariationLocation.length < input.length  {
      
      let skinVariationExtracted = input.substring(with: match.rangeAt(2))
      
      if skinVariationExtracted.characters.count > 0 {
        skinVariationString = skinVariationExtracted
      }
    }
    
    guard let emojiObject = getEmojiFromAlias(alias) else { return nil }
    
    let emoji: String
    if let skinVariationStringUnWrapped = skinVariationString, let skinVariation = SkinVariations(rawValue: skinVariationStringUnWrapped.uppercased()){
      emoji = emojiObject.getEmojiWithSkinVariation(skinVariation)
    } else {
      emoji = emojiObject.emoji
    }
    return emoji
      
    } catch {
      return nil
    }
  }
  
  open static func getEmojiFromUnified(_ unified: String) -> String {
    
    return Emoji(shortName: "", unified: unified).emoji
  }
  
  static func getEmojiFromAlias(_ alias: String) -> Emoji? {
    
    guard let emoji = emojiManager.shortNameForUnified[alias] else { return nil }
    
    return emoji
  }
  
  open static func parseUnicode(_ input: String) -> String {
    
    var result = input
    
//    let uniqueChars = Array(Set(input.unicodeScalars.filter{!$0.isASCII}.map { String($0) }))

    let uniqueChars = Array(Set(input.characters.map { String($0) }))
    
    uniqueChars.forEach {
      
      if let leaf = emojiManager.getLeafForBytes(bytes: [UInt8]($0.utf8)) {
       
        let alias = leaf.emojis.sorted(by: {$0.0.shortName.characters.count < $0.1.shortName.characters.count})[0].shortName
        
        result = result.replacingOccurrences(of: $0, with: ":\(alias):")
        
      }
    }
    
    return result
    
  }
  
  open static func parseAliases(_ input: String) -> String {
    
    var result = input
    
    do {
      
      let aliasMatchingRegex = try NSRegularExpression(pattern: ":([\\w_+-]+)(?:(?:\\||::)(type_[\\w_]*))?:", options: .caseInsensitive)
      
      let matches = aliasMatchingRegex.matches(in: input, options: .withoutAnchoringBounds, range: NSRange(location: 0, length: input.characters.count))
      
      if(matches.count == 0) {
        return input
      }
      
      let nsInput = input as NSString

      var uniqueMatches: [String:NSTextCheckingResult] = [:]
      
      matches.forEach {
      
        let fullAlias = nsInput.substring(with: $0.rangeAt(0))
        
        if uniqueMatches.index(forKey: fullAlias) == nil {
          
          uniqueMatches[fullAlias] = $0
        }
        
      }
    
      uniqueMatches
        .map { fullAlias, match in
          
          guard let emoji = getUnicodeFromAlias(fullAlias) else { return nil }
         
          return ( fullAlias, emoji ) as (String, String)?
        }
        .filter { (value: (String, String)?) in
          value != nil
        }
        .map { return $0! }
        .sorted(by: { $0.0.0.characters.count > $0.1.0.characters.count }) // Execute the longer first so emojis with skin variations are executed before the ones without
        .forEach { (value: (String,String) )in
          
          let fullAlias = value.0
          let emoji = value.1
          
          result = result.replacingOccurrences(of: fullAlias, with: emoji)
      }
    } catch {}
    
    return result
  }
  
}