import SwiftUI
import SwiftData
import IFCore
import IFStorage

struct AISettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = AISettingsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("AI 模型配置")
                    .font(.title2.bold())
                Spacer()
                Button("添加模型", systemImage: "plus") {
                    vm.startNew()
                }
            }
            .padding()

            if vm.configs.isEmpty {
                ContentUnavailableView {
                    Label("暂无模型配置", systemImage: "cpu")
                } description: {
                    Text("添加一个 AI 模型来开始使用分析功能")
                } actions: {
                    Button("添加模型") { vm.startNew() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(vm.configs) { config in
                        AIModelRow(config: config, vm: vm)
                    }
                }
            }
        }
        .onAppear { vm.load(context: modelContext) }
        .sheet(isPresented: $vm.isShowingEditor) {
            AIModelEditorSheet(vm: vm)
        }
    }
}

private struct AIModelRow: View {
    let config: AIModelConfig
    @Bindable var vm: AISettingsViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(config.name).font(.headline)
                    if config.isDefault {
                        Text("默认")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                Text("\(config.provider.displayName) · \(config.modelId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            if vm.isTesting {
                ProgressView().controlSize(.small)
            }
            if let result = vm.testResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("成功") ? .green : .red)
            }

            Button("测试") { vm.testConnection(config) }
                .disabled(vm.isTesting)
            Button("编辑") { vm.startEdit(config) }
            Button(role: .destructive) { vm.delete(config) } label: {
                Image(systemName: "trash")
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AIModelEditorSheet: View {
    @Bindable var vm: AISettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(vm.editingConfig == nil ? "添加 AI 模型" : "编辑 AI 模型")
                .font(.title3.bold())

            Form {
                TextField("名称", text: $vm.name)
                Picker("提供商", selection: $vm.provider) {
                    ForEach(AIProvider.allCases, id: \.self) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                TextField("模型 ID", text: $vm.modelId)
                    .help("例如: gpt-4o, claude-sonnet-4-5-20250929")
                if vm.provider == .custom {
                    TextField("API Endpoint", text: $vm.endpoint)
                }
                SecureField("API Key", text: $vm.apiKey)
                Toggle("设为默认", isOn: $vm.isDefault)
            }
            .formStyle(.grouped)

            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("保存") { vm.save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(vm.name.isEmpty || vm.modelId.isEmpty)
            }
        }
        .padding()
        .frame(width: 450)
    }
}
