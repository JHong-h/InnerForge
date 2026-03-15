import SwiftUI
import SwiftData
import IFCore

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isCompleted: Bool
    @State private var step = 0
    @State private var aiVM = AISettingsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i <= step ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()

            Group {
                switch step {
                case 0: welcomeStep
                case 1: aiConfigStep
                case 2: readyStep
                default: EmptyView()
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            .animation(.easeInOut(duration: 0.3), value: step)

            Spacer()

            // Navigation
            HStack {
                if step > 0 {
                    Button("上一步") { step -= 1 }
                }
                Spacer()
                if step < 2 {
                    Button("下一步") { step += 1 }
                        .buttonStyle(.borderedProminent)
                        .disabled(step == 1 && aiVM.configs.isEmpty)
                } else {
                    Button("开始使用") {
                        isCompleted = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 440)
        .onAppear { aiVM.load(context: modelContext) }
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.accent)
            Text("欢迎使用 InnerForge")
                .font(.largeTitle.bold())
            Text("通过「自我观察 → 剖析 → 重构」的循环，\n借助 AI 辅助实现个人成长。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
        }
    }

    private var aiConfigStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 40))
                .foregroundStyle(.accent)
            Text("配置 AI 模型")
                .font(.title2.bold())
            Text("添加一个 AI 模型来启用分析功能。\n支持 OpenAI、Anthropic 或任何 OpenAI 兼容接口。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)

            if aiVM.configs.isEmpty {
                Button("添加模型") { aiVM.startNew() }
                    .buttonStyle(.borderedProminent)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("已配置: \(aiVM.configs.first!.name)")
                }
                .padding(8)
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .sheet(isPresented: $aiVM.isShowingEditor) {
            AIModelEditorOnboarding(vm: aiVM)
        }
    }

    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("一切就绪")
                .font(.title2.bold())
            Text("接下来你可以：\n1. 创建一个观察期，设定你的观察意图\n2. 每天记录你的行为和想法\n3. 让 AI 帮你分析和生成重构方案")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
        }
    }
}

private struct AIModelEditorOnboarding: View {
    @Bindable var vm: AISettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("添加 AI 模型")
                .font(.title3.bold())
            Form {
                TextField("名称", text: $vm.name)
                Picker("提供商", selection: $vm.provider) {
                    ForEach(AIProvider.allCases, id: \.self) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                TextField("模型 ID", text: $vm.modelId)
                if vm.provider == .custom {
                    TextField("API Endpoint", text: $vm.endpoint)
                }
                SecureField("API Key", text: $vm.apiKey)
            }
            .formStyle(.grouped)

            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("保存") { vm.save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.name.isEmpty || vm.modelId.isEmpty)
            }
        }
        .padding()
        .frame(width: 420)
    }
}
