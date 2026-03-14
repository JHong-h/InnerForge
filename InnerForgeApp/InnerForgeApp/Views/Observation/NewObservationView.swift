import SwiftUI
import IFCore

struct NewObservationView: View {
    @Bindable var vm: ObservationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("创建新观察期")
                .font(.title3.bold())

            Form {
                TextField("标题", text: $vm.newTitle)
                    .help("例如：提升专注力、改善睡眠习惯")

                TextField("观察意图", text: $vm.newIntention, axis: .vertical)
                    .lineLimit(3...6)
                    .help("你希望在这个观察期中关注什么？")

                Stepper("观察天数: \(vm.newDuration) 天", value: $vm.newDuration, in: 7...90)
                    .help("最少 7 天")
            }
            .formStyle(.grouped)

            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("开始观察") { vm.createPeriod() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.newTitle.isEmpty)
            }
        }
        .padding()
        .frame(width: 420)
    }
}
