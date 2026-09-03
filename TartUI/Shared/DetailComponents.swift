import AppKit
import SwiftUI

struct ResourceHeader<Actions: View>: View {
    let systemName: String
    let color: Color
    let title: String
    let status: String
    let isRunning: Bool
    @ViewBuilder let actions: Actions

    init(
        systemName: String,
        color: Color,
        title: String,
        status: String,
        isRunning: Bool = false,
        @ViewBuilder actions: () -> Actions
    ) {
        self.systemName = systemName
        self.color = color
        self.title = title
        self.status = status
        self.isRunning = isRunning
        self.actions = actions()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: systemName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 54, height: 54)
                .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(2)
                    .textSelection(.enabled)
                StatusText(status: status, isRunning: isRunning)
            }
            Spacer(minLength: 20)
            actions
        }
        .padding(.bottom, 16)
    }
}

struct MetadataStrip: View {
    struct Item: Identifiable {
        let id = UUID()
        let systemName: String
        let value: String
    }

    let items: [Item]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(items) { item in
                Label(item.value, systemImage: item.systemName)
                    .lineLimit(1)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.bottom, 8)
    }
}

struct SectionPanel<Content: View>: View {
    let title: LocalizedStringKey
    let systemName: String
    @ViewBuilder let content: Content

    init(
        _ title: LocalizedStringKey,
        systemName: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemName = systemName
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(title, systemImage: systemName)
                .font(.headline.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            Color.primary.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

struct InfoRow: View {
    let label: LocalizedStringKey
    let value: String
    let monospaced: Bool

    init(_ label: LocalizedStringKey, value: String, monospaced: Bool = false) {
        self.label = label
        self.value = value
        self.monospaced = monospaced
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 132, alignment: .leading)
            Text(value)
                .font(.callout)
                .fontDesign(monospaced ? .monospaced : .default)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }
}

struct InfoGrid: View {
    struct Item: Identifiable {
        let id = UUID()
        let label: LocalizedStringKey
        let value: String
    }

    let items: [Item]
    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 24)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.value)
                        .font(.callout.weight(.medium))
                        .textSelection(.enabled)
                }
            }
        }
    }
}

struct StatusText: View {
    let status: String
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isRunning ? Color.green : Color.secondary.opacity(0.55))
                .frame(width: 7, height: 7)
            Text(status)
                .font(.callout)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.quaternary, in: Capsule())
    }
}

struct CodeWell: View {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    var body: some View {
        Text(value)
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

struct UnavailableRow: View {
    let systemName: String
    let text: LocalizedStringKey

    var body: some View {
        Label(text, systemImage: systemName)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}
