//
//  Card.swift
//  Flashzilla
//
//  Created by Waveline Media on 1/14/21.
//

import Foundation

struct Card {
    let prompt: String
    let answer: String

    static var example: Card {
        Card(prompt: "Who played the 13th Doctor in Doctor Who?", answer: "Jodie Whittaker")
    }
}
