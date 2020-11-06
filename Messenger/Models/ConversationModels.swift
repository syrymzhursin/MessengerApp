//
//  ConversationModels.swift
//  Messenger
//
//  Created by User on 11/6/20.
//  Copyright © 2020 Syrym Zhursin. All rights reserved.
//

import Foundation
struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}
struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
