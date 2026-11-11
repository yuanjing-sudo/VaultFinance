import SwiftUI

struct ContentView: View {
    @EnvironmentObject var navigation: NavigationModel
    @EnvironmentObject var storage: LocalStorage
    @StateObject var sidebar = Sidebar()
    
    var body: some View {
        VStack(spacing: 0) {
            // Sidebar
            Sidebar()
                .frame(width: 220)
                .background(Color(.systemBackground))
            
            // Main content
            NavigationStack(path: $navigation.path) {
                VStack {
                    // Header with breadcrumbs and profile button
                    HStack {
                        Button(action: { navigation.navigateBack() }) {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Text(navigation.currentDestination)
                            .font(.headline)
                            .bold()
                        
                        Spacer()
                        
                        Button(action { navigation.navigate(to: "Profile") }) {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    
                    // Breadcrumbs trail
                    if navigation.breadcrumbs.count > 1 {
                        HStack(spacing: 4) {
                            ForEach(navigation.breadcrumbs.dropFirst(), id: \ .self) { crumb in
                                Text(crumb)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                + Text(" > ")
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Dashboard cards
                            HStack(spacing: 16) {
                                StatCard(label: "Income", value: Money(amount: storage.profile.totalMonthlyIncome).formatted(), trend: "+2.1%", positive: true)
                                StatCard(label: "Saved", value: Money(amount: storage.assets.reduce(0) { $0 + $1.currentMarketValue }).formatted(), trend: "+5.4%", positive: true)
                            }
                            
                            // Quick stats grid
                            HStack(spacing: 16) {
                                StatCard(label: "Budget", value: "\(storage.categories.count) categories", trend: "", positive: false)
                                StatCard(label: "Goals", value: "\(storage.goals.filter { $0.isComplete }.count) complete", trend: "", positive: false)
                                StatCard(label: "Streak", value: "\(navigation.streakCount) day streak", trend: "", positive: false)
                            }
                            
                            // Quick links grid
                            VStack(spacing: 16) {
                                NavigationLink(destination: BudgetView().environmentObject(storage).environmentObject(navigation)) {
                                    HStack {
                                        Image(systemName: "square.grid.2x2")
                                        Text("Budget")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                
                                NavigationLink(destination: CalendarSpendingView().environmentObject(storage).environmentObject(navigation)) {
                                    HStack {
                                        Image(systemName: "calendar")
                                        Text("Spending Calendar")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                
                                NavigationLink(destination: ProfileEditView().environmentObject(storage).environmentObject(navigation)) {
                                    HStack {
                                        Image(systemName: "person.text.rectangle")
                                        Text("Profile")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                
                                NavigationLink(destination: GoalsView().environmentObject(storage).environmentObject(navigation)) {
                                    HStack {
                                        Image(systemName: "target")
                                        Text("Goals")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                
                                NavigationLink(destination: AchievementsView().environmentObject(storage).environmentObject(navigation)) {
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                        Text("Achievements")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Vault")
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}
