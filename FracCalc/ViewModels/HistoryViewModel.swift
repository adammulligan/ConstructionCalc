import SwiftUI
import SwiftData

@Observable
class HistoryViewModel {
    var entries: [HistoryEntry] = []

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<HistoryEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        entries = (try? context.fetch(descriptor)) ?? []
    }

    func addEntry(_ entry: HistoryEntry, context: ModelContext) {
        context.insert(entry)
        try? context.save()
        load(context: context)
    }

    func deleteEntry(_ entry: HistoryEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
        load(context: context)
    }

    func clearAll(context: ModelContext) {
        for entry in entries {
            context.delete(entry)
        }
        try? context.save()
        entries = []
    }
}
