//
//  DatabaseManager.swift
//  Messenger
//
//  Created by User on 7/18/20.
//  Copyright © 2020 Syrym Zhursin. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
}

extension DatabaseManager {
    public func getDataFor(path: String, comletion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                comletion(.failure(DatabaseError.failedToFetch))
                return
            }
            comletion(.success(value))
        }
    }
}

// MARK: - Account Management
extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void))  {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
           database.child(user.safeEmail).setValue([
               "first_name": user.firstName,
               "last_name": user.lastName
           ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            /*
             users => [
             [
                "name":
                "safe_email":
             ]
             [
                "name":
                "safe_email":
             ]
             ]
             
             */
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else {
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
            })
       }
    public func getAllUsers(completion: @escaping(Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}
// MARK: - Sending messages / conversations

extension DatabaseManager {
    
    /*
            "uduqnas" {
                "messages": [
                    {
                        "id": String,
                        "type": text, photo, video
                        "content": String,
                        "date": Date(),
                        "sender_email": String,
                        "isRead": true/false,
                        
                    }
                            ]
        
            }
     
            
                
     
            conversation => [
                [
                    "conversation_id": "uduqnas"
                    "other_user_email":
                    "latest_message": => {
                    "date": Date()
                    "latest_message": "message"
                    "is_read": true/false
                    }
                ]
            ]
     
     */
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
        let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                    
                ]
            ]
            
            let recipientNewConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                    
                ]
            ]
            // Update recipient conversation entry
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipientNewConversationData)
            self?.database.child("\(otherUserEmail)/conversations").setValue(conversationId)

                }
                else {
                    // create
            self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            })
            
            // Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exist for current user
                // you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationId: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                    
                })
            }
            else {
                // conversation array does not exist
                // create it
               userNode["conversations"] = [
                newConversationData
                ]
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                    conversationId: conversationId,
                                                    firstMessage: firstMessage,
                                                    completion: completion)
                })
            }
        })
    }
    /// Fetches and returns all conversations for the user with passed email
    private func finishCreatingConversation(name: String, conversationId: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
//        {
    //        "id": String,
    //        "type": text, photo, video
    //        "content": String,
    //        "date": Date(),
    //        "sender_email": String,
    //        "isRead": true/false,
//        }
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email":currentUserEmail,
            "is_read": false,
            "name": name
        ]
        let value: [String: Any] = [
            "messages": [
                collectionMessage  
            ]
        ]
        print("Adding convo: \(conversationId)")
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                let name = dictionary["name"] as? String,
                let otherUserEmail = dictionary["other_user_email"] as? String,
                let latestMessage = dictionary["latest_message"] as? [String: Any],
                let date = latestMessage["date"] as? String,
                let message = latestMessage["message"] as? String,
                let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
                
            })
            completion(.success(conversations))
        })
    }
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
                   guard let value = snapshot.value as? [[String: Any]] else {
                       completion(.failure(DatabaseError.failedToFetch))
                       return
                   }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageId = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let type = dictionary["type"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateString)
                    else {
                        return nil
                }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender,
                               messageId: messageId,
                               sentDate: date,
                               kind: .text(content))
            })
                   completion(.success(messages))
               })
    }
    /// Sends a messages for a given conversation
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // Add new message to messages
        // Update sender latest message
        // Update recipient latest message
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
           completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(email: myEmail)
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email":currentUserEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    var targetConversation: [String: Any]?
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = finalConversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations, withCompletionBlock: {error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        // Update latest message for recipient user
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            var targetConversation: [String: Any]?
                            var position = 0
                            
                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            targetConversation?["latest_message"] = updatedValue
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = finalConversation
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations, withCompletionBlock: {error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
            }
        })
    }
}




struct ChatAppUser {
    let firstName: String
    let lastName: String
    let email: String
    
    var safeEmail: String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
    var profilePictureFileName: String {
        
        return "\(safeEmail)_profile_picture.png"
    }
}

