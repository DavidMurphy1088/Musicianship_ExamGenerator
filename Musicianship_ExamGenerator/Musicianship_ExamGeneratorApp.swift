//
//  Musicianship_ExamGeneratorApp.swift
//  Musicianship_ExamGenerator
//
//  Created by David Murphy on 8/26/23.
//

import SwiftUI

@main
struct Musicianship_ExamGeneratorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
