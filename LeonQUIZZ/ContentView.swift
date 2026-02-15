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
    @Environment(\.dismiss) private var dismiss

    @State private var questionCouleur: Color = .red
    @State private var questionForme: String = "Cercle"
    @State private var questionChiffre: Int = 1
    @State private var questionLettre: String = "A"
    @State private var questionPersonnage: String = "totoro"
    @State private var estQuestionChiffre: Bool = false
    @State private var estQuestionLettre: Bool = false
    @State private var estQuestionPersonnage: Bool = false
    @State private var score: Int = 0
    @State private var questionIndex: Int = 0
    @State private var showScoreSheet: Bool = false
    @State private var finalScreenBlink: Bool = false
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
    private let speechSynth = AVSpeechSynthesizer()

    let couleurs: [Color] = [.red, .blue, .green, .yellow, .orange, .purple]
    let formes: [String] = ["Cercle", "Carré", "Triangle"]
    let chiffres: [Int] = Array(1...29)
    let lettres: [String] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
    let personnages: [String] = [
        "totoro", "chihiro", "ponyo", "kiki", "jiji", "calcifer", "howl", "san", "haku",
        "sheeta", "kaguya", "sosuke", "the_mask", "chat_bus", "satsuki", "mei",
        "singe_better_man", "sony_hayes"
    ]
    let tailleForme: CGFloat = 100
    let taillePersonnage: CGFloat = 180

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
                        .padding(.top, 2)
                        .padding(.horizontal, 20)
                        Spacer()
                        Text("Question \(questionIndex)/\(totalQuestions)")
                            .font(.subheadline)
                            .padding(.bottom, 36)
                    }

                    ForEach(Array(chiffresAffiches.enumerated()), id: \.offset) { index, pair in
                        if positions.indices.contains(index) && (estQuestionChiffre || estQuestionLettre || estQuestionPersonnage) {
                            let pos = positions[index]
                            let valeur = pair.0
                            let fond = pair.1

                            Button(action: {
                                if peutRepondre {
                                    if estQuestionChiffre {
                                        verifierReponseChiffre(chiffre: Int(valeur)!)
                                    } else if estQuestionLettre {
                                        verifierReponseLettre(lettre: valeur)
                                    } else if estQuestionPersonnage {
                                        verifierReponsePersonnage(personnage: valeur)
                                    }
                                }
                            }) {
                                if estQuestionPersonnage {
                                    personnageView(nom: valeur, fond: fond)
                                } else {
                                    Text(valeur)
                                        .font(.system(size: 40, weight: .bold))
                                    .frame(width: estQuestionPersonnage ? taillePersonnage : tailleForme, height: estQuestionPersonnage ? taillePersonnage : tailleForme)
                                    .background(fond.opacity(0.9))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            .opacity(blinking && index == correctIndex && blink ? 0.2 : 1)
                            .position(pos)
                        }
                    }

                    ForEach(Array(formesAffichees.enumerated()), id: \.offset) { index, item in
                        if positions.indices.contains(index) && !estQuestionChiffre && !estQuestionLettre && !estQuestionPersonnage {
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

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button("Menu") {
                                dismiss()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .font(.headline)
                            .cornerRadius(12)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .zIndex(2)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .onAppear {
                    setupAudioEngine()
                    geometrySize = geo.size
                    nouvelleQuestion(size: geo.size)
                }

                if showScoreSheet {
                    ZStack {
                        (score >= totalQuestions
                            ? (finalScreenBlink ? Color.yellow : Color.orange)
                            : Color.white)
                            .ignoresSafeArea()

                        VStack(spacing: 24) {
                            Text("Quiz terminé !")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)

                            Text("Score \(score)/\(totalQuestions)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))

                            if score >= totalQuestions {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.28))
                                        .frame(width: 250, height: 250)
                                    Text("🏆")
                                        .font(.system(size: 170))
                                }
                            }

                            Spacer()

                            HStack {
                                Spacer()
                                Button("Menu") {
                                    dismiss()
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .font(.headline)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                    }
                    .onAppear {
                        if score >= totalQuestions {
                            finalScreenBlink = false
                            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                                finalScreenBlink = true
                            }
                        }
                    }
                    .zIndex(10)
                }
            }
            .navigationBarHidden(true)
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

    func personnageView(nom: String, fond: Color) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12)
                .fill(fond.opacity(0.9))
                .frame(width: taillePersonnage, height: taillePersonnage)
            Image(nom)
                .resizable()
                .scaledToFill()
                .frame(width: taillePersonnage, height: taillePersonnage)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(nomAffichagePersonnage(nom))
                .font(.caption2.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.black.opacity(0.5))
                .cornerRadius(6)
                .padding(.bottom, 4)
        }
        .frame(width: taillePersonnage, height: taillePersonnage)
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
        } else if estQuestionPersonnage {
            lireQuestionPersonnage(personnage: questionPersonnage)
        } else {
            lireQuestionForme(forme: questionForme, couleur: nomDeCouleur(couleur: questionCouleur))
        }
    }

    func nomAffichagePersonnage(_ id: String) -> String {
        switch id {
        case "the_mask": return "The Mask"
        case "chat_bus": return "Chat Bus"
        case "singe_better_man": return "Singe Better Man"
        case "sony_hayes": return "Sony Hayes"
        default: return id.replacingOccurrences(of: "_", with: " ").capitalized
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

    func verifierReponsePersonnage(personnage: String) {
        let bonne = (personnage == questionPersonnage)
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
            finalScreenBlink = false
            showScoreSheet = true
            return
        }
        questionIndex += 1
        peutRepondre = false

        switch mode {
        case .chiffres:
            estQuestionChiffre = true
            estQuestionLettre = false
            estQuestionPersonnage = false
        case .lettres:
            estQuestionChiffre = false
            estQuestionLettre = true
            estQuestionPersonnage = false
        case .formes:
            estQuestionChiffre = false
            estQuestionLettre = false
            estQuestionPersonnage = false
        case .mix:
            let tirage = Int.random(in: 0...2)
            estQuestionChiffre = (tirage == 0)
            estQuestionLettre = (tirage == 1)
            estQuestionPersonnage = false
        case .personnages:
            estQuestionChiffre = false
            estQuestionLettre = false
            estQuestionPersonnage = true
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
        } else if estQuestionPersonnage {
            questionPersonnage = personnages.randomElement()!
            var set = Set<String>()
            set.insert(questionPersonnage)
            while set.count < 9 {
                set.insert(personnages.randomElement()!)
            }
            chiffresAffiches = Array(set).shuffled().map { ($0, couleurs.randomElement()!) }
            correctIndex = chiffresAffiches.firstIndex(where: { $0.0 == questionPersonnage })
            lireQuestionPersonnage(personnage: questionPersonnage)
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
        let horizontalPadding: CGFloat = 34
        let topPadding: CGFloat = 64
        let bottomPadding: CGFloat = 130
        let cellWidth = (size.width - horizontalPadding * 2) / CGFloat(cols)
        let cellHeight = (size.height - topPadding - bottomPadding) / CGFloat(rows)

        var gridPositions: [CGPoint] = []

        for row in 0..<rows {
            for col in 0..<cols {
                let x = horizontalPadding + cellWidth * (CGFloat(col) + 0.5)
                let y = topPadding + cellHeight * (CGFloat(row) + 0.5)
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
            let nomFichier = "\(chiffre)"
            if Bundle.main.url(forResource: nomFichier, withExtension: "m4a") != nil {
                jouerSonAvecPitch(nomFichier: nomFichier)
            } else {
                dire("\(chiffre)")
            }
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

    func lireQuestionPersonnage(personnage: String) {
        jouerSonAvecPitch(nomFichier: "ou_est_le")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dire(nomAffichagePersonnage(personnage))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            peutRepondre = true
        }
    }

    func dire(_ texte: String) {
        let utterance = AVSpeechUtterance(string: texte)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = 0.5
        speechSynth.speak(utterance)
    }

    func startBlinking() {
        blinking = true
        blink = false
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            blink = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            blinking = false
            blink = false
            nouvelleQuestion(size: geometrySize)
        }
    }
}
