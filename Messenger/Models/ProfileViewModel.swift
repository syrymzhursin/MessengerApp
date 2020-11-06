//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by User on 11/6/20.
//  Copyright © 2020 Syrym Zhursin. All rights reserved.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}
struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
