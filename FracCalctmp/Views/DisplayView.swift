import SwiftUI

struct DisplayView: View {
    let text: String
    let hasMemory: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if hasMemory {
                Text("M")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text(text)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
