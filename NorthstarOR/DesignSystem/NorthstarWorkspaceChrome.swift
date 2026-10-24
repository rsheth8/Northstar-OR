import SwiftUI

/// Brand identity stays separate from native tab and destination navigation.
struct NorthstarWorkspaceHeader: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Northstar.Space.s6) {
                identity
                Spacer(minLength: Northstar.Space.s4)
                context
            }
            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                identity
                context
            }
        }
        .padding(.horizontal, Northstar.Space.s6)
        .padding(.vertical, Northstar.Space.s3)
        .foregroundStyle(Northstar.Palette.Workspace.onHeader)
        .background(Northstar.Palette.Workspace.header)
    }

    private var identity: some View {
        HStack(spacing: Northstar.Space.s3) {
            Image("BrandMark")
                .resizable().scaledToFit().frame(width: 40, height: 28)
                .accessibilityHidden(true)
            Text("Northstar OR").font(Northstar.Fonts.bodyStrong)
        }
        .accessibilityElement(children: .combine)
    }

    private var context: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Northstar.Space.s4) { contextLabels }
            VStack(alignment: .leading, spacing: Northstar.Space.s2) { contextLabels }
        }
        .font(Northstar.Fonts.supporting)
        .foregroundStyle(Northstar.Palette.Workspace.onHeaderSecondary)
    }

    @ViewBuilder private var contextLabels: some View {
        Text("Fictional sample workspace")
        Label("On this device", systemImage: "ipad.landscape")
    }
}

/// Shared flat section hierarchy for the working surface.
struct NorthstarWorkSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            Text(title).font(Northstar.Fonts.bodyStrong)
                .foregroundStyle(Northstar.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NorthstarCaseContext: View {
    let reference: String
    let site: String
    let state: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Northstar.Space.s6) { fields }
            VStack(alignment: .leading, spacing: Northstar.Space.s2) { fields }
        }
        .padding(.horizontal, Northstar.Space.s6)
        .padding(.vertical, Northstar.Space.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Northstar.Palette.bgSunken)
    }

    @ViewBuilder private var fields: some View {
        Text(reference).font(Northstar.Fonts.bodyStrong).foregroundStyle(Northstar.Palette.ink)
        Text(site).font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
        Text(state).font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
    }
}
