import SwiftUI
import AVFoundation

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct FormeCouleur: Hashable {
    let forme: String
    let couleurNom: String
}



struct ContentView: View {
    let mode: QuizMode

    @State private var questionCouleur: Color = .red
    @State private var questionForme: String = "Cercle"
    @State private var questionChiffre: Int = 1
    @State private var questionLettre: String = "A"
    @State private var estQuestionChiffre: Bool = false
    @State private var estQuestionLettre: Bool = false
    @State private var score: Int = 0
    @State private var questionIndex: Int = 0
    @State private var showScoreSheet: Bool = false
    @State private var geometrySize: CGSize = .zero

    let totalQuestions = 10
    @State private var formesAffichees: [(String, Color)] = []
    @State private var chiffresAffiches: [(String, Color)] = []
    @State private var positions: [CGPoint] = []

    @State private var audioEngine = AVAudioEngine()
    @State private var pitchEffect = AVAudioUnitTimePitch()
    @State private var audioPlayerNode = AVAudioPlayerNode()

    @State private var peutRepondre: Bool = false
    @State private var correctIndex: Int? = nil
    @State private var blinking: Bool = false
    @State private var blink: Bool = false

    let couleurs: [Color] = [.red, .blue, .green, .yellow, .orange, .purple]
    let formes: [String] = ["Cercle", "Carré", "Triangle"]
    let chiffres: [Int] = Array(1...9)
    let lettres: [String] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
    let tailleForme: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            ZStack {
                    ZStack {
                        VStack {
                            HStack {
                                Text("Score: \(score)")
                                    .font(.headline)
                                Spacer()
                                Button("Répéter") {
                                    repeterDerniereQuestion()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .font(.headline)
                                .cornerRadius(12)
                            }
                            .padding(.top, 40)
                            .padding(.horizontal, 20)
                            Spacer()
                            Text("Question \(questionIndex)/\(totalQuestions)")
                                .font(.subheadline)
                                .padding(.bottom, 10)
                        }

                        ForEach(Array(chiffresAffiches.enumerated()), id: \.offset) { index, pair in
                            if positions.indices.contains(index) {
                                let pos = positions[index]
                                let valeur = pair.0
                                let fond = pair.1

                                Button(action: {
                                    if peutRepondre {
                                        if estQuestionChiffre {
                                            verifierReponseChiffre(chiffre: Int(valeur)!)
                                        } else if estQuestionLettre {
                                            verifierReponseLettre(lettre: valeur)
                                        }
                                    }
                                }) {
                                    Text(valeur)
                                        .font(.system(size: 40, weight: .bold))
                                        .frame(width: tailleForme, height: tailleForme)
                                        .background(fond.opacity(0.9))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .opacity(blinking && index == correctIndex && blink ? 0.2 : 1)
                                .position(pos)
                            }
                        }

                        ForEach(Array(formesAffichees.enumerated()), id: \.offset) { index, item in
                            if positions.indices.contains(index) && !estQuestionChiffre && !estQuestionLettre {
                                let pos = positions[index]
                                let (forme, couleur) = item
                                Button(action: {
                                    if peutRepondre {
                                        verifierReponseForme(couleur: couleur, forme: forme)
                                    }
                                }) {
                                    formeView(forme: forme, couleur: couleur)
                                        .frame(width: tailleForme, height: tailleForme)
                                }
                                .opacity(blinking && index == correctIndex && blink ? 0.2 : 1)
                                .position(pos)
                            }
                        }

                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .onAppear {
                setupAudioEngine()
                geometrySize = geo.size
                nouvelleQuestion(size: geo.size)
            }
            .alert("Quiz terminé !", isPresented: $showScoreSheet) {
                Button("Recommencer") {
                    questionIndex = 0
                    score = 0
                    nouvelleQuestion(size: geometrySize)
                }
            } message: {
                Text("Votre score est \(score)/\(totalQuestions)")
            }
        }
    }

    func formeView(forme: String, couleur: Color) -> some View {
        Group {
            if forme == "Cercle" {
                Circle().fill(couleur)
            } else if forme == "Carré" {
                Rectangle().fill(couleur)
            } else {
                TriangleShape().fill(couleur)
            }
        }
    }

    func setupAudioEngine() {
        audioEngine.attach(audioPlayerNode)
        audioEngine.attach(pitchEffect)
        pitchEffect.pitch = 300
        audioEngine.connect(audioPlayerNode, to: pitchEffect, format: nil)
        audioEngine.connect(pitchEffect, to: audioEngine.mainMixerNode, format: nil)
        try? audioEngine.start()
    }

    func jouerSonAvecPitch(nomFichier: String) {
        if let url = Bundle.main.url(forResource: nomFichier, withExtension: "m4a") {
            if let audioFile = try? AVAudioFile(forReading: url) {
                audioPlayerNode.stop()
                audioPlayerNode.scheduleFile(audioFile, at: nil)
                audioPlayerNode.play()
            }
        }
    }

    func repeterDerniereQuestion() {
        if estQuestionChiffre {
            lireQuestionChiffre(chiffre: questionChiffre)
        } else if estQuestionLettre {
            lireQuestionLettre(lettre: questionLettre)
        } else {
            lireQuestionForme(forme: questionForme, couleur: nomDeCouleur(couleur: questionCouleur))
        }
    }

    func nomDeCouleur(couleur: Color) -> String {
        switch couleur {
        case .red: return "rouge"
        case .blue: return "bleu"
        case .green: return "vert"
        case .yellow: return "jaune"
        case .orange: return "orange"
        case .purple: return "violet"
        default: return "inconnue"
        }
    }

    func couleurDepuisNom(nom: String) -> Color {
        switch nom {
        case "rouge": return .red
        case "bleu": return .blue
        case "vert": return .green
        case "jaune": return .yellow
        case "orange": return .orange
        case "violet": return .purple
        default: return .gray
        }
    }

    func verifierReponseForme(couleur: Color, forme: String) {
        let bonne = (forme == questionForme && couleur == questionCouleur)
        peutRepondre = false
        score += bonne ? 1 : -1
        jouerSonAvecPitch(nomFichier: bonne ? "bravo" : "non")
        startBlinking()
    }

    func verifierReponseChiffre(chiffre: Int) {
        let bonne = (chiffre == questionChiffre)
        peutRepondre = false
        score += bonne ? 1 : -1
        jouerSonAvecPitch(nomFichier: bonne ? "bravo" : "non")
        startBlinking()
    }

    func verifierReponseLettre(lettre: String) {
        let bonne = (lettre == questionLettre)
        peutRepondre = false
        score += bonne ? 1 : -1
        jouerSonAvecPitch(nomFichier: bonne ? "bravo" : "non")
        startBlinking()
    }

    func nouvelleQuestion(size: CGSize) {
        geometrySize = size
        blinking = false
        blink = false
        if questionIndex == totalQuestions {
            showScoreSheet = true
            return
        }
        questionIndex += 1
        peutRepondre = false

        switch mode {
        case .chiffres:
            estQuestionChiffre = true
            estQuestionLettre = false
        case .lettres:
            estQuestionChiffre = false
            estQuestionLettre = true
        case .formes:
            estQuestionChiffre = false
            estQuestionLettre = false
        case .mix:
            let tirage = Int.random(in: 0...2)
            estQuestionChiffre = (tirage == 0)
            estQuestionLettre = (tirage == 1)
        }

        positions = genererPositionsAleatoires(size: size)

        if estQuestionChiffre {
            questionChiffre = chiffres.randomElement()!
            var set = Set<Int>()
            set.insert(questionChiffre)
            while set.count < 9 {
                set.insert(chiffres.randomElement()!)
            }
            chiffresAffiches = Array(set).shuffled().map { (String($0), couleurs.randomElement()!) }
            correctIndex = chiffresAffiches.firstIndex(where: { Int($0.0)! == questionChiffre })
            lireQuestionChiffre(chiffre: questionChiffre)
        } else if estQuestionLettre {
            questionLettre = lettres.randomElement()!
            var set = Set<String>()
            set.insert(questionLettre)
            while set.count < 9 {
                set.insert(lettres.randomElement()!)
            }
            chiffresAffiches = Array(set).shuffled().map { ($0, couleurs.randomElement()!) }
            correctIndex = chiffresAffiches.firstIndex(where: { $0.0 == questionLettre })
            lireQuestionLettre(lettre: questionLettre)
        } else {
            questionCouleur = couleurs.randomElement()!
            questionForme = formes.randomElement()!
            let bonneReponse = FormeCouleur(forme: questionForme, couleurNom: nomDeCouleur(couleur: questionCouleur))
            var set = Set<FormeCouleur>()
            set.insert(bonneReponse)
            while set.count < 9 {
                let f = formes.randomElement()!
                let c = couleurs.randomElement()!
                set.insert(FormeCouleur(forme: f, couleurNom: nomDeCouleur(couleur: c)))
            }
            formesAffichees = set.map { ($0.forme, couleurDepuisNom(nom: $0.couleurNom)) }.shuffled()
            correctIndex = formesAffichees.firstIndex(where: { $0.0 == questionForme && $0.1 == questionCouleur })
            lireQuestionForme(forme: questionForme, couleur: nomDeCouleur(couleur: questionCouleur))
        }
    }

    func genererPositionsAleatoires(size: CGSize) -> [CGPoint] {
        let cols = 3
        let rows = 3
        let padding: CGFloat = 60
        let cellWidth = (size.width - padding * 2) / CGFloat(cols)
        let cellHeight = (size.height - padding * 2) / CGFloat(rows)

        var gridPositions: [CGPoint] = []

        for row in 0..<rows {
            for col in 0..<cols {
                let x = padding + cellWidth * (CGFloat(col) + 0.5)
                let y = padding + cellHeight * (CGFloat(row) + 0.5)
                gridPositions.append(CGPoint(x: x, y: y))
            }
        }

        return gridPositions.shuffled()
    }

    func lireQuestionForme(forme: String, couleur: String) {
        jouerSonAvecPitch(nomFichier: "ou_est_le")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            jouerSonAvecPitch(nomFichier: forme.lowercased())
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            jouerSonAvecPitch(nomFichier: couleur.lowercased())
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            peutRepondre = true
        }
    }

    func lireQuestionChiffre(chiffre: Int) {
        jouerSonAvecPitch(nomFichier: "ou_est_le")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            jouerSonAvecPitch(nomFichier: "\(chiffre)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            peutRepondre = true
        }
    }

    func lireQuestionLettre(lettre: String) {
        jouerSonAvecPitch(nomFichier: "ou_est_le")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            jouerSonAvecPitch(nomFichier: lettre.lowercased())
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            peutRepondre = true
        }
    }

    func startBlinking() {
        blinking = true
        blink = false
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            blink = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            blinking = false
            blink = false
            nouvelleQuestion(size: geometrySize)
        }
    }
}
