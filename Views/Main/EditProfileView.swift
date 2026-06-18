import SwiftUI
import PhotosUI
import UIKit

struct EditProfileView: View {
    let profile: UserProfile
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var firstName: String
    @State private var lastName: String
    @State private var bio: String
    @State private var profilePhotoURL: String?
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var croppedProfileImage: UIImage?
    @State private var cropSourceImage: UIImage?
    @State private var isShowingCrop = false
    @State private var isSaving = false
    @State private var errorText: String?

    private let service = ProfileService()
    private let maxBioLength = 150

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryColor: Color {
        foregroundColor.opacity(0.62)
    }

    private var fieldFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }

    private var primaryButtonFill: Color {
        Color.jbiAccent(for: colorScheme)
    }

    private var primaryButtonText: Color {
        colorScheme == .dark ? JBITheme.darkBlue : .white
    }

    init(profile: UserProfile, onSaved: @escaping () -> Void) {
        self.profile = profile
        self.onSaved = onSaved
        _firstName = State(initialValue: profile.firstName)
        _lastName = State(initialValue: profile.lastName)
        _bio = State(initialValue: profile.bio ?? "")
        _profilePhotoURL = State(initialValue: profile.profilePhotoURL)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        avatarEditor
                        fields

                        if let errorText {
                            Text(errorText)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.red.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(colorScheme == .dark ? Color.black : Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(foregroundColor.opacity(0.82))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving" : "Save") { save() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(foregroundColor)
                        .disabled(isSaving)
                }
            }
            .onChange(of: selectedProfileItem) { _, newItem in
                loadImage(from: newItem)
            }
            .sheet(isPresented: $isShowingCrop) {
                if let cropSourceImage {
                    ProfilePhotoCropView(
                        image: cropSourceImage,
                        onCancel: {
                            selectedProfileItem = nil
                            isShowingCrop = false
                        },
                        onUsePhoto: { cropped in
                            croppedProfileImage = cropped
                            profilePhotoURL = nil
                            isShowingCrop = false
                        }
                    )
                }
            }
        }
    }

    private var avatarEditor: some View {
        VStack(spacing: 12) {
            avatarPreview
                .frame(width: 116, height: 116)
                .clipShape(Circle())
                .overlay(Circle().stroke(foregroundColor.opacity(0.82), lineWidth: 2))

            ViewThatFits(in: .horizontal) {
                imageControlRow
                VStack(spacing: 10) {
                    imageControlRow
                }
            }
        }
    }

    private var imageControlRow: some View {
        HStack(spacing: 10) {
            PhotosPicker(selection: $selectedProfileItem, matching: .images) {
                editChip("Change")
            }

            Button {
                selectedProfileItem = nil
                croppedProfileImage = nil
                profilePhotoURL = nil
                errorText = nil
            } label: {
                editChip("Remove")
            }
            .buttonStyle(.plain)

            Button {
                editCurrentPhoto()
            } label: {
                editChip("Edit")
            }
            .buttonStyle(.plain)
            .opacity(canEditPhoto ? 1 : 0.48)
        }
    }

    private var canEditPhoto: Bool {
        croppedProfileImage != nil || profilePhotoURL != nil
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let croppedProfileImage {
            Image(uiImage: croppedProfileImage)
                .resizable()
                .scaledToFill()
        } else if let profilePhotoURL, let url = URL(string: profilePhotoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ProfileAvatarView(profile: profile, size: 116)
                }
            }
        } else {
            ProfileAvatarView(profile: profile, size: 116)
        }
    }

    private var fields: some View {
        VStack(spacing: 14) {
            editField("First name", text: $firstName)
            editField("Last name", text: $lastName)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Bio")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(secondaryColor)
                    Spacer()
                    Text("\(bio.count)/\(maxBioLength)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(bio.count > maxBioLength ? .red : secondaryColor)
                }

                TextEditor(text: $bio)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(foregroundColor)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 92)
                    .padding(10)
                    .background(fieldFill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onChange(of: bio) { _, newValue in
                        if newValue.count > maxBioLength {
                            bio = String(newValue.prefix(maxBioLength))
                        }
                    }
            }
        }
    }

    private func editField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(secondaryColor)
            TextField(title, text: text)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(foregroundColor)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(fieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func editChip(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(primaryButtonText)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(primaryButtonFill)
            .clipShape(Capsule())
    }

    private func editCurrentPhoto() {
        if let croppedProfileImage {
            cropSourceImage = croppedProfileImage
            isShowingCrop = true
            return
        }

        guard let profilePhotoURL, let url = URL(string: profilePhotoURL) else {
            errorText = "Add a photo first."
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { throw ProfileServiceError.uploadFailed }
                await MainActor.run {
                    cropSourceImage = image
                    isShowingCrop = true
                }
            } catch {
                print("EditProfileView current image load failed:", error)
                await MainActor.run {
                    errorText = "Could not load that photo. Try again."
                }
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { return }
                guard let image = UIImage(data: data) else { return }
                await MainActor.run {
                    cropSourceImage = image
                    isShowingCrop = true
                }
            } catch {
                print("EditProfileView image load failed:", error)
                await MainActor.run {
                    errorText = "Could not load that photo. Try again."
                }
            }
        }
    }

    private func save() {
        guard !isSaving else { return }

        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedBio.count <= maxBioLength else {
            errorText = "Please keep your bio under 150 characters."
            return
        }

        isSaving = true
        errorText = nil

        Task {
            do {
                var nextProfileURL = profilePhotoURL

                if let croppedProfileImage {
                    nextProfileURL = try await service.uploadProfilePhoto(croppedProfileImage, userId: profile.id)
                } else if nextProfileURL == nil, profile.profilePhotoURL != nil {
                    try await service.removeProfilePhoto(userId: profile.id)
                }

                try await service.updateProfile(
                    profile: profile,
                    firstName: firstName,
                    lastName: lastName,
                    bio: trimmedBio,
                    profilePhotoURL: nextProfileURL,
                    backdropPhotoURL: profile.backdropPhotoURL
                )

                await MainActor.run {
                    isSaving = false
                    onSaved()
                    dismiss()
                }
            } catch {
                print("EditProfileView save failed:", error)
                await MainActor.run {
                    isSaving = false
                    errorText = error.localizedDescription
                }
            }
        }
    }
}
