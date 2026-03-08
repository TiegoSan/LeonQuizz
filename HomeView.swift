import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let items: [QuizMenuItem] = [
        QuizMenuItem(mode: .formes, title: "Les formes", subtitle: "Reconnaître cercle, carré, triangle", icon: "square.on.circle.fill", colors: [Color(red: 0.98, green: 0.44, blue: 0.36), Color(red: 0.96, green: 0.72, blue: 0.28)]),
        QuizMenuItem(mode: .chiffres, title: "Les chiffres", subtitle: "Compter et repérer les nombres", icon: "numbers.rectangle.fill", colors: [Color(red: 0.22, green: 0.60, blue: 0.98), Color(red: 0.26, green: 0.84, blue: 0.88)]),
        QuizMenuItem(mode: .lettres, title: "Les lettres", subtitle: "Identifier l'alphabet", icon: "textformat.abc", colors: [Color(red: 0.54, green: 0.39, blue: 0.92), Color(red: 0.78, green: 0.45, blue: 0.94)]),
        QuizMenuItem(mode: .mix, title: "Mélange", subtitle: "Un peu de tout", icon: "sparkles.rectangle.stack.fill", colors: [Color(red: 0.11, green: 0.72, blue: 0.41), Color(red: 0.28, green: 0.88, blue: 0.57)]),
        QuizMenuItem(mode: .personnages, title: "Personnages", subtitle: "Retrouver les héros", icon: "person.3.sequence.fill", colors: [Color(red: 0.95, green: 0.29, blue: 0.60), Color(red: 1.00, green: 0.55, blue: 0.39)])
    ]

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.98, blue: 1.00),
                            Color(red: 0.91, green: 0.95, blue: 1.00)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    Circle()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 280, height: 280)
                        .blur(radius: 20)
                        .offset(x: -130, y: -290)

                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 260, height: 260)
                        .blur(radius: 25)
                        .offset(x: 150, y: 300)

                    Group {
                        if horizontalSizeClass == .regular {
                            contentView(compactCards: true)
                        } else {
                            ScrollView(showsIndicators: false) {
                                contentView(compactCards: false)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, horizontalSizeClass == .regular ? 12 : 20)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private func contentView(compactCards: Bool) -> some View {
        VStack(alignment: .leading, spacing: compactCards ? 14 : 24) {
            Text("Le quizz de Léon")
                .font(.system(size: compactCards ? 40 : 46, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.14, green: 0.24, blue: 0.44), Color(red: 0.20, green: 0.45, blue: 0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, compactCards ? 8 : 16)

            Text("Choisis un thème")
                .font(.system(size: compactCards ? 18 : 20, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.7))

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: compactCards ? 12 : 16), count: compactCards ? 3 : 2),
                spacing: compactCards ? 12 : 16
            ) {
                ForEach(items) { item in
                    NavigationLink(destination: ContentView(mode: item.mode)) {
                        QuizCardView(item: item, compact: compactCards)
                    }
                    .buttonStyle(.plain)
                }
            }

            if horizontalSizeClass == .regular {
                Spacer(minLength: 0)
            }
        }
    }
}

struct QuizMenuItem: Identifiable {
    let id = UUID()
    let mode: QuizMode
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
}

struct QuizCardView: View {
    let item: QuizMenuItem
    let compact: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: compact ? 24 : 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: item.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 24 : 28, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                )
                .shadow(color: item.colors.first?.opacity(0.45) ?? .clear, radius: compact ? 10 : 16, x: 0, y: compact ? 6 : 10)

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: compact ? 90 : 130, height: compact ? 90 : 130)
                .offset(x: compact ? 22 : 28, y: compact ? -22 : -28)

            VStack(alignment: .leading, spacing: compact ? 8 : 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.24))
                        .frame(width: compact ? 66 : 94, height: compact ? 66 : 94)

                    Image(systemName: item.icon)
                        .font(.system(size: compact ? 32 : 48, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 3)
                }

                Text(item.title)
                    .font(.system(size: compact ? 21 : 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(item.subtitle)
                    .font(.system(size: compact ? 12 : 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.9))
                    .lineLimit(compact ? 1 : 2)

                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: compact ? 20 : 24, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                }
            }
            .padding(compact ? 12 : 16)
        }
        .frame(height: compact ? 170 : 230)
    }
}

enum QuizMode {
    case formes, chiffres, lettres, mix, personnages
}
