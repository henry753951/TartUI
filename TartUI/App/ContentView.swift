import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var model: TartAppModel
    @State var deleteTarget: DeleteTarget?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            HStack(spacing: 0) {
                resourceList
                    .frame(width: 310)
                    .frame(maxHeight: .infinity)
                    .background(resourcePaneBackground)
                Divider()
                    .opacity(0.45)
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(model.currentSection.title)
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $model.searchText, placement: .toolbar, prompt: searchPrompt)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if model.isRefreshing || model.isPerformingAction {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    Task { await model.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(model.isRefreshing || model.isPerformingAction)

                Button {
                    model.showAddSheet()
                } label: {
                    Label(addButtonTitle, systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(model.isPerformingAction)
            }
        }
        .sheet(item: $model.sheetRoute) { route in
            switch route {
            case .addImage:
                AddImageSheet(defaultReference: model.settings.defaultImageReference) { options in
                    Task { await model.pullImage(options) }
                }
            case .createVM:
                CreateVMSheet(
                    images: model.images,
                    virtualMachines: model.virtualMachines,
                    preferredImage: model.selectedImage
                ) { options in
                    Task { await model.createVM(options) }
                }
            case .runVM:
                if let vm = model.selectedVM {
                    RunVMSheet(vm: vm, initialOptions: model.runOptions) { options in
                        Task { await model.runSelectedVM(options: options) }
                    }
                }
            case .editVM:
                EditVMSheet(initialOptions: model.editOptions) { options in
                    Task { await model.saveVMSettings(options) }
                }
            }
        }
        .alert(item: $deleteTarget) { target in
            Alert(
                title: Text(target.title),
                message: Text(target.message),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        switch target {
                        case .image:
                            await model.deleteSelectedImage()
                        case .virtualMachine:
                            await model.deleteSelectedVM()
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(
            "Tart Error",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.dismissError() } }
            )
        ) {
            Button("OK") { model.dismissError() }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            if CommandLine.arguments.contains("--sidebar-hidden") {
                columnVisibility = .detailOnly
            }
            await model.load()
            if CommandLine.arguments.contains("--show-run-sheet") {
                model.prepareRunSheet()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            guard !model.tartVersion.isEmpty else { return }
            Task { await model.refresh() }
        }
    }
}
