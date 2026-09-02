import Foundation

struct RunOptionsStore {
    private let defaults = UserDefaults.standard

    func load(for virtualMachine: String) -> RunOptions? {
        guard let data = defaults.data(forKey: key(for: virtualMachine)) else { return nil }
        return try? JSONDecoder().decode(RunOptions.self, from: data)
    }

    func save(_ options: RunOptions, for virtualMachine: String) {
        guard let data = try? JSONEncoder().encode(options) else { return }
        defaults.set(data, forKey: key(for: virtualMachine))
    }

    func move(from oldName: String, to newName: String) {
        guard let options = load(for: oldName) else { return }
        save(options, for: newName)
        defaults.removeObject(forKey: key(for: oldName))
    }

    func remove(for virtualMachine: String) {
        defaults.removeObject(forKey: key(for: virtualMachine))
    }

    private func key(for virtualMachine: String) -> String {
        "dev.henry.TartUI.runOptions.\(virtualMachine)"
    }
}
