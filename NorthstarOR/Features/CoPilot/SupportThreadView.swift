import SwiftUI

/// The same chronological case thread used by Co-pilot, Remote Support and the laptop page.
struct SupportThreadView: View {
    let entries: [SupportThreadEntry]
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s2) {
            Text("Case messages").font(Northstar.Fonts.bodyStrong)
            if entries.isEmpty {
                Text("No messages in this case yet.")
                    .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            }
            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: Northstar.Space.s1) {
                    Text("\(entry.title) · \(entry.at.formatted(date: .omitted, time: .shortened))")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    Text(entry.text).font(Northstar.Fonts.body).textSelection(.enabled)
                    if let delivery = entry.delivery {
                        Text(delivery.label).font(Northstar.Fonts.supporting)
                            .foregroundStyle(delivery == .failed ? Northstar.Palette.alert : Northstar.Palette.inkMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Northstar.Space.s2)
                Divider()
            }
        }
    }
}

struct SessionNoteComposer: View {
    @Environment(AppModel.self) private var model
    @State private var error: String?
    private var draft: Binding<String> {
        Binding(get: { (try? model.noteDraftKey()).map { model.draft(for: $0) } ?? "" }, set: {
            if let key = try? model.noteDraftKey() { try? model.setDraft($0, for: key) }
        })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            TextField("Write a message for this case", text: draft, axis: .vertical)
                .lineLimit(1...4)
                .font(Northstar.Fonts.body)
                .padding(Northstar.Space.s3)
                .frame(minHeight: Northstar.Target.minimum)
                .background(Northstar.Palette.bgRaised, in: RoundedRectangle(cornerRadius: Northstar.Radius.sm))
                .accessibilityIdentifier("session-note-draft")
            Button("Send message", action: send)
                .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                .disabled(draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("session-note-send")
            if let error { Text(error).font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.alert) }
            Text("A message does not confirm a checklist item.")
                .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
        }
    }
    private func send() {
        do {
            _ = try model.sendSessionNote(text: draft.wrappedValue)
            draft.wrappedValue = ""
            model.flushPendingSave()
            error = nil
        } catch {
            self.error = "Not sent. Your message is kept."
        }
    }
}
