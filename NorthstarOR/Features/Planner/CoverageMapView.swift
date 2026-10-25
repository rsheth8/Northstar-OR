import SwiftUI
import MapKit

struct CoverageMapView: View {
    let procedures: [Procedure]
    let sites: [Hospital]
    @Binding var selectedID: String?
    private var mappedSites: [Hospital] {
        sites.filter { site in procedures.contains { $0.hospitalID == site.id } && PlannerScope.validCoordinate(latitude: site.latitude, longitude: site.longitude) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            Text("Recorded sites").font(Northstar.Fonts.title)
            Text("Fictional site coordinates · No routes or live representative positions.")
                .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            if mappedSites.isEmpty {
                ContentUnavailableView("No recorded coordinates", systemImage: "map", description: Text("Cases remain available in the list below. Add fictional site coordinates in Workspace settings."))
            } else {
                Map {
                    ForEach(mappedSites) { site in
                        Annotation(site.name, coordinate: CLLocationCoordinate2D(latitude: site.latitude!, longitude: site.longitude!)) {
                            Button {
                                selectedID = procedures.first(where: { $0.hospitalID == site.id })?.id
                            } label: {
                                Image(systemName: "building.2.crop.circle.fill").font(.title).padding(8)
                                    .background(Northstar.Palette.bgRaised, in: Circle())
                            }
                            .accessibilityLabel("Select case at \(site.name)")
                        }
                    }
                }
                .frame(minHeight: 260, idealHeight: 340)
            }
            Text("Case list · Available even when map tiles are unavailable").font(Northstar.Fonts.bodyStrong)
            ForEach(procedures) { procedure in
                Button { selectedID = procedure.id } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(procedure.reference ?? procedure.id).font(Northstar.Fonts.bodyStrong)
                            Text(sites.first(where: { $0.id == procedure.hospitalID })?.name ?? "Site not recorded")
                        }
                        Spacer()
                        if selectedID == procedure.id { Image(systemName: "checkmark.circle.fill") }
                    }.frame(minHeight: Northstar.Target.minimum)
                }.buttonStyle(.plain)
            }
        }
    }
}
