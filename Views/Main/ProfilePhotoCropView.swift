import SwiftUI
import UIKit

struct ProfilePhotoCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onUsePhoto: (UIImage) -> Void

    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let cropSize = min(geometry.size.width - 48, 340)

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    cropPreview(size: cropSize)

                    Text("Move and zoom")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer(minLength: 16)

                    HStack(spacing: 14) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.white.opacity(0.14))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            onUsePhoto(image.renderedSquareCrop(cropSize: cropSize, zoom: zoom, offset: offset))
                        } label: {
                            Text("Use Photo")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 12))
                }
            }
        }
    }

    private func cropPreview(size: CGFloat) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .scaleEffect(zoom)
                .offset(offset)
                .frame(width: size, height: size)
                .clipShape(Circle())
                .gesture(dragGesture)
                .simultaneousGesture(magnificationGesture)

            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: size, height: size)
                .allowsHitTesting(false)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoom = min(max(lastZoom * value, 1), 4)
            }
            .onEnded { _ in
                lastZoom = zoom
            }
    }
}

private extension UIImage {
    func renderedSquareCrop(cropSize: CGFloat, zoom: CGFloat, offset: CGSize) -> UIImage {
        let targetSize = CGSize(width: 768, height: 768)
        let imageSize = size
        let baseScale = max(cropSize / imageSize.width, cropSize / imageSize.height)
        let previewDrawSize = CGSize(
            width: imageSize.width * baseScale * zoom,
            height: imageSize.height * baseScale * zoom
        )
        let previewOrigin = CGPoint(
            x: (cropSize - previewDrawSize.width) / 2 + offset.width,
            y: (cropSize - previewDrawSize.height) / 2 + offset.height
        )
        let outputScale = targetSize.width / cropSize
        let outputRect = CGRect(
            x: previewOrigin.x * outputScale,
            y: previewOrigin.y * outputScale,
            width: previewDrawSize.width * outputScale,
            height: previewDrawSize.height * outputScale
        )

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            draw(in: outputRect)
        }
    }
}
