import SwiftUI

struct ContactSupportView: View {
    @State private var selectedSubject = "General"
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var sending = false
    @State private var successBanner = false
    @State private var errorBanner: String?

    private let backendURL = URL(string: "https://feedback-board.iocompile67692.workers.dev/api/feedback")!
    private let maxMessageLength = 1000

    private struct SubjectOption: Identifiable {
        let title: String
        let icon: String
        var id: String { title }
    }

    private let options: [SubjectOption] = [
        .init(title: "General", icon: "bubble.left.fill"),
        .init(title: "Feature Suggestion", icon: "lightbulb.fill"),
        .init(title: "Bug Report", icon: "ant.fill"),
        .init(title: "Usage Question", icon: "questionmark.circle.fill"),
        .init(title: "Performance Issue", icon: "gauge.with.dots.needle.67percent"),
        .init(title: "UI Improvement", icon: "paintpalette.fill"),
        .init(title: "Other", icon: "ellipsis.circle.fill")
    ]

    private var emailValid: Bool {
        email.contains("@") && email.contains(".") && !email.hasPrefix("@") && !email.hasSuffix(".")
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && emailValid
            && (selectedSubject != "Other" || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
            && !sending
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                subjectGrid
                if selectedSubject == "Other" {
                    TextField("Custom subject", text: $customSubject)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name").font(.subheadline.weight(.medium))
                    TextField("Your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Your name")
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email").font(.subheadline.weight(.medium))
                    TextField("yourname@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Your email address")
                    if !email.isEmpty && !emailValid {
                        Text("Please enter a valid email address.").font(.caption).foregroundStyle(.red)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Message").font(.subheadline.weight(.medium))
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("Tell us what's on your mind...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .onChange(of: message) { _, newValue in
                            if newValue.count > maxMessageLength {
                                message = String(newValue.prefix(maxMessageLength))
                            }
                        }
                        .accessibilityLabel("Your feedback message")
                    Text("\(message.count) / \(maxMessageLength)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Button {
                    submit()
                } label: {
                    HStack {
                        if sending { ProgressView().tint(.white) }
                        Text(sending ? "Sending…" : "Submit")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
                .accessibilityLabel("Submit feedback")
                Text("We only use your email to respond to this feedback.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
        }
        .navigationTitle("Contact Support")
        .overlay(alignment: .top) {
            if successBanner {
                feedbackBanner(text: "Thank you! Your feedback has been sent.", tint: .green)
                    .task {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        successBanner = false
                    }
            } else if let errorBanner {
                feedbackBanner(text: errorBanner, tint: .red)
                    .task {
                        try? await Task.sleep(nanoseconds: 3_500_000_000)
                        self.errorBanner = nil
                    }
            }
        }
    }

    private func feedbackBanner(text: String, tint: Color) -> some View {
        Label(text, systemImage: tint == .green ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(tint, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var subjectGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(options) { option in
                let isSelected = selectedSubject == option.title
                Button {
                    selectedSubject = option.title
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : option.icon)
                            .font(.title3)
                        Text(option.title)
                            .font(.caption.weight(.medium))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isSelected ? Color.mint.opacity(0.18) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Color.mint : Color(.separator), lineWidth: isSelected ? 2 : 1))
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Subject: \(option.title)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func submit() {
        sending = true
        let subject = selectedSubject == "Other" ? customSubject : selectedSubject
        let payload: [String: String] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "email": email.trimmingCharacters(in: .whitespaces),
            "subject": subject,
            "message": message.trimmingCharacters(in: .whitespaces),
            "app_name": "CraveFade"
        ]
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        Task {
            defer { sending = false }
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    errorBanner = "Something went wrong. Please try again."
                    return
                }
                _ = data
                successBanner = true
                name = ""
                email = ""
                message = ""
                customSubject = ""
                selectedSubject = "General"
            } catch {
                errorBanner = "Network error. Please check your connection and try again."
            }
        }
    }
}
