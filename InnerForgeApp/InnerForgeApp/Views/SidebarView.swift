import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?

    var body: some View {
        List(SidebarSection.allCases, id: \.self, selection: $selection) { section in
            Label(section.rawValue, systemImage: section.icon)
        }
        .listStyle(.sidebar)
        .navigationTitle("InnerForge")
        .frame(minWidth: 180)
    }
}
