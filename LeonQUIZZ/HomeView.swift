import SwiftUI
import AVFoundation

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text("Le quizz de Léon")
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .padding(.top, 50)

                Spacer()

                VStack(spacing: 25) {
                    NavigationLink(destination: ContentView(mode: .formes)) {
                        MenuButtonView(title: "🎨 Les formes")
                    }
                    NavigationLink(destination: ContentView(mode: .chiffres)) {
                        MenuButtonView(title: "🔢 Les chiffres")
                    }
                    NavigationLink(destination: ContentView(mode: .lettres)) {
                        MenuButtonView(title: "🔤 Les lettres")
                    }
                    NavigationLink(destination: ContentView(mode: .mix)) {
                        MenuButtonView(title: "🎲 Mélange")
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.white, Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MenuButtonView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(20)
            .shadow(radius: 5)
    }
}

enum QuizMode {
    case formes, chiffres, lettres, mix
}
