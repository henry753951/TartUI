import AppKit
import SwiftUI

extension ContentView {
    var sidebar: some View {
        List(selection: $model.selection) {
            Section {
                ForEach(AppSection.allCases) { section in
                    Label {
                        HStack(spacing: 8) {
                            Text(section.title)
                                .lineLimit(1)
                                .layoutPriority(1)
                            Spacer(minLength: 6)
                            Text(count(for: section), format: .number)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                        }
                    } icon: {
                        Image(systemName: section.systemImage)
                            .frame(width: 18)
                    }
                    .tag(section)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Tart")
        .navigationSplitViewColumnWidth(min: 230, ideal: 250, max: 310)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                SettingsLink {
                    Label("Settings…", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)

                if !model.tartVersion.isEmpty {
                    Divider()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 7, height: 7)
                        Text("Tart \(model.tartVersion)")
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                }
            }
            .padding(.vertical, 10)
        }
        .onChange(of: model.selection) { oldValue, newValue in
            guard let newValue, oldValue != newValue else { return }
            model.selectSection(newValue)
        }
    }

    @ViewBuilder
    var resourceList: some View {
        switch model.currentSection {
        case .images:
            List(model.filteredImages, selection: $model.selectedImageID) { image in
                ImageRow(image: image)
                    .tag(image.id)
                    .contextMenu {
                        Button("Create Virtual Machine") { model.showCreateVM(from: image) }
                        Divider()
                        Button("Delete Image", role: .destructive) {
                            model.selectedImageID = image.id
                            deleteTarget = .image(image.reference)
                        }
                    }
            }
            .overlay { imageEmptyState }
            .scrollContentBackground(.hidden)
            .onChange(of: model.selectedImageID) { _, id in
                guard let id, let image = model.images.first(where: { $0.id == id }) else { return }
                model.selectImage(image)
            }
        case .virtualMachines:
            List(model.filteredVMs, selection: $model.selectedVMID) { vm in
                VMRow(vm: vm)
                    .tag(vm.id)
                    .contextMenu {
                        if vm.running {
                            Button("Stop") {
                                model.selectedVMID = vm.id
                                Task { await model.stopSelectedVM() }
                            }
                        } else {
                            Button("Run") {
                                model.selectedVMID = vm.id
                                Task {
                                    await model.selectVM(vm)
                                    await model.quickRunSelectedVM()
                                }
                            }
                            Button("Run With Options…") {
                                model.selectedVMID = vm.id
                                Task {
                                    await model.selectVM(vm)
                                    model.prepareRunSheet()
                                }
                            }
                            Button("Edit Settings…") {
                                model.selectedVMID = vm.id
                                Task {
                                    await model.selectVM(vm)
                                    model.prepareEditSheet()
                                }
                            }
                        }
                        Divider()
                        Button("Reveal in Finder") {
                            model.selectedVMID = vm.id
                            Task {
                                await model.selectVM(vm)
                                model.revealSelectedVMLocation()
                            }
                        }
                        Button("Delete Virtual Machine", role: .destructive) {
                            model.selectedVMID = vm.id
                            deleteTarget = .virtualMachine(vm.name)
                        }
                    }
            }
            .overlay { vmEmptyState }
            .scrollContentBackground(.hidden)
            .onChange(of: model.selectedVMID) { _, id in
                guard let id, let vm = model.virtualMachines.first(where: { $0.id == id }) else { return }
                Task { await model.selectVM(vm) }
            }
        }
    }

    @ViewBuilder
    var detail: some View {
        ZStack(alignment: .top) {
            switch model.currentSection {
            case .images:
                if let image = model.selectedImage {
                    ImageDetailView(image: image) {
                        model.showCreateVM(from: image)
                    } onDelete: {
                        deleteTarget = .image(image.reference)
                    }
                } else {
                    ContentUnavailableView("Select an Image", systemImage: "square.stack.3d.up")
                }
            case .virtualMachines:
                if let vm = model.selectedVM {
                    VMDetailView(model: model, vm: vm) {
                        deleteTarget = .virtualMachine(vm.name)
                    }
                } else {
                    ContentUnavailableView("Select a Virtual Machine", systemImage: "macwindow")
                }
            }

            if let message = model.activityMessage {
                Text(message)
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
                    .padding(.top, 10)
            }
        }
    }

    @ViewBuilder
    var imageEmptyState: some View {
        if model.filteredImages.isEmpty && !model.isRefreshing {
            ContentUnavailableView(
                model.images.isEmpty ? String(localized: "No Images") : String(localized: "No Results"),
                systemImage: "square.stack.3d.up",
                description: Text(
                    model.images.isEmpty
                        ? String(localized: "Add an OCI image to use it as a virtual machine source.")
                        : String(localized: "Try another search."))
            )
        }
    }

    @ViewBuilder
    var vmEmptyState: some View {
        if model.filteredVMs.isEmpty && !model.isRefreshing {
            ContentUnavailableView(
                model.virtualMachines.isEmpty
                    ? String(localized: "No Virtual Machines") : String(localized: "No Results"),
                systemImage: "macwindow",
                description: Text(
                    model.virtualMachines.isEmpty
                        ? String(localized: "Create a virtual machine from an image.")
                        : String(localized: "Try another search."))
            )
        }
    }

    var searchPrompt: String {
        model.currentSection == .images
            ? String(localized: "Search images") : String(localized: "Search virtual machines")
    }

    var addButtonTitle: String {
        model.currentSection == .images ? String(localized: "Add Image") : String(localized: "Create Virtual Machine")
    }

    var resourcePaneBackground: some View {
        Color(nsColor: .windowBackgroundColor)
            .overlay(Color.primary.opacity(0.018))
    }

    func count(for section: AppSection) -> Int {
        switch section {
        case .images: model.images.count
        case .virtualMachines: model.virtualMachines.count
        }
    }
}
