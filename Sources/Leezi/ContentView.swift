import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var speech = SpeechController()
    @State private var text: String = ""
    @State private var isDropTargeted = false
    @State private var isProcessingAI = false
    @State private var aiErrorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Leezi — Lecteur de texte")
                .font(.title2).bold()

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isDropTargeted ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.05)))

                if text.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("Glissez-déposez un fichier texte ici,\nou collez du texte ci-dessous.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                }

                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .opacity(text.isEmpty ? 0.85 : 1)
            }
            .frame(minHeight: 260)
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers: providers)
            }
            .onChange(of: text) { _, newValue in
                speech.load(text: newValue)
            }

            if let aiErrorMessage {
                Text(aiErrorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button {
                    Task { await cleanupWithAI() }
                } label: {
                    if isProcessingAI {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Nettoyer avec l'IA", systemImage: "sparkles")
                    }
                }
                .disabled(text.isEmpty || isProcessingAI)

                Spacer()

                Picker("Voix", selection: $speech.gender) {
                    ForEach(VoiceGender.allCases) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Vitesse de lecture")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $speech.rate, in: 0...1)
            }

            ProgressView(value: speech.progress)

            HStack(spacing: 24) {
                Button {
                    speech.skip(seconds: -10)
                } label: {
                    Image(systemName: "gobackward.10").font(.title)
                }

                Button {
                    speech.isSpeaking ? speech.pause() : speech.play()
                } label: {
                    Image(systemName: speech.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                .disabled(text.isEmpty)

                Button {
                    speech.skip(seconds: 10)
                } label: {
                    Image(systemName: "goforward.10").font(.title)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 560)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                DispatchQueue.main.async {
                    text = content
                }
            }
        }
        return true
    }

    private func cleanupWithAI() async {
        isProcessingAI = true
        aiErrorMessage = nil
        defer { isProcessingAI = false }
        do {
            let client = OllamaClient()
            let result = try await client.chat(
                systemPrompt: "Tu nettoies un texte pour la lecture à voix haute : corrige la mise en forme, retire les artefacts inutiles (numéros de page, en-têtes), mais garde le sens et la langue d'origine intacts. Réponds uniquement avec le texte nettoyé.",
                userText: text
            )
            text = result
        } catch {
            aiErrorMessage = error.localizedDescription
        }
    }
}
