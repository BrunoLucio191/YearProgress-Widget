import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            
            Color.primary.colorInvert()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 60))
                    .foregroundStyle(.primary)
                
                Text("Year Progress")
                    .font(.largeTitle)
                    .bold()
                
                Text(yearProgressString())
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                Text("Add the Widget to your Homescreen.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
            }
        }
    }
    
    // Simple function to calcule year percentage
    func yearProgressString() -> String {
        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let start = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let end = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        
        let total = end.timeIntervalSince(start)
        let passed = now.timeIntervalSince(start)
        let percentage = (passed / total) * 100
        
        return String(format: "%.1f%%", percentage)
    }
}

#Preview {
    ContentView()
}
