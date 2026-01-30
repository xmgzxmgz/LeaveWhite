import SwiftUI
import LeaveWhiteCore

struct MainTabView: View {
    @Bindable var security: SecurityManager

    var body: some View {
        TabView {
            DashboardView(security: security)
                .tabItem {
                    Label {
                        Text("tab.dashboard", bundle: .module)
                    } icon: {
                        Image(systemName: "shield.lefthalf.filled")
                    }
                }

            VaultView(security: security)
                .tabItem {
                    Label {
                        Text("tab.vault", bundle: .module)
                    } icon: {
                        Image(systemName: "lock.rectangle.stack")
                    }
                }

            EchoChronosView(security: security)
                .tabItem {
                    Label {
                        Text("tab.echo", bundle: .module)
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
        }
        .tint(Theme.gold)
    }
}

