import SwiftUI

struct ImageRow: View {
    let image: TartImage

    var body: some View {
        HStack(spacing: 11) {
            ResourceIcon(systemName: "square.stack.3d.up.fill", color: .blue)
            VStack(alignment: .leading, spacing: 3) {
                Text(image.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text("OCI · \(image.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text("\(image.sizeGB) GB")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }
}

struct VMRow: View {
    let vm: TartVirtualMachine

    var body: some View {
        HStack(spacing: 11) {
            ResourceIcon(systemName: "macwindow", color: .primary)
            VStack(alignment: .leading, spacing: 3) {
                Text(vm.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                StateLabel(state: vm.state)
            }
            Spacer(minLength: 6)
            Text("\(vm.sizeGB) GB")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }
}

private struct ResourceIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StateLabel: View {
    let state: VMState

    var body: some View {
        Label(state.title, systemImage: state.symbol)
            .font(.caption)
            .foregroundStyle(color)
    }

    private var color: Color {
        switch state {
        case .running: .green
        case .stopped: .secondary
        case .suspended: .orange
        }
    }
}
