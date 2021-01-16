//
//  ContentView.swift
//  Flashzilla
//
//  Created by Waveline Media on 1/14/21.
//

import SwiftUI
import CoreHaptics

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = CGFloat(total - position)
        return self.offset(CGSize(width: 0, height: offset * 10))
    }
}

struct ContentView: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityEnabled) var accessibilityEnabled
    
    @State private var cards = [Card]()
    @State private var isActive = true
    @State private var timeRemaining = 100
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var showingEditScreen = false
    
    @State private var showingSettingScreen = false
    @State private var reuseCards = false
    
    @State private var engine: CHHapticEngine?
    
    var body: some View {
        ZStack {
            Image(decorative: "background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Time: \(timeRemaining)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black)
                            .opacity(0.75)
                    )
                
                ZStack {
                    ForEach(0 ..< cards.count, id: \.self) {index in
                        CardView(card: cards[index]) {
                            withAnimation {
                                if reuseCards {
                                    self.pushCardToBack(at: index)
                                } else {
                                    self.removeCard(at: index)
                                }
                                self.errorHaptic()
                            }
                        }
                        .stacked(at: index, in: self.cards.count)
                        .allowsHitTesting(index == self.cards.count - 1)
                        .accessibilityHidden(index < self.cards.count - 1)
                    }
                }
                .allowsTightening(timeRemaining > 0)
                
                if cards.isEmpty {
                    Button("Start Again", action: resetCards)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
                
            VStack {
                HStack {
                    Spacer()

                    Button(action: {
                        self.showingEditScreen = true
                    }) {
                        Image(systemName: "plus.circle")
                            .defaultButtonStyle()
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        self.showingSettingScreen = true
                    }) {
                        Image(systemName: "gear")
                            .defaultButtonStyle()
                    }
                }

                Spacer()
            }
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding()
                
            if differentiateWithoutColor || accessibilityEnabled {
                VStack {
                    Spacer()
                    
                    HStack {
                        AccessibilityButton(imageName: "xmark.circle",
                                            accessibilityLabel: "Wrong",
                                            accessibilityHint: "Mark your answer as being incorrect") {
                            if reuseCards {
                                self.pushCardToBack(at: self.cards.count - 1)
                            } else {
                                self.removeCard(at: self.cards.count - 1)
                            }
                            self.errorHaptic()
                        }
                        
                        Spacer()
                        
                        AccessibilityButton(imageName: "checkmark.circle",
                                            accessibilityLabel: "Correct",
                                            accessibilityHint: "Mark your answer as being correct") {
                            self.removeCard(at: self.cards.count - 1)
                        }
                    }
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding()
                }
            }
        }
        .onReceive(timer) {time in
            guard self.isActive else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            self.isActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if cards.isEmpty == false {
                self.isActive = true
            }
        }
        .sheet(isPresented: $showingEditScreen, onDismiss: resetCards) {
            EditCardsView()
        }
        .sheet(isPresented: $showingSettingScreen, onDismiss: nil) {
            SettingsView(reuseCards: self.$reuseCards)
        }
        .onAppear(perform: performFunctions)
    }
    
    func performFunctions() {
        resetCards()
        prepareHaptics()
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            self.engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
    
    func errorHaptic() {
        // make sure that the device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        // create one intense, sharp tap
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
        let eventOne = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(eventOne)
        let eventTwo = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1)
        events.append(eventTwo)

        // convert those events into a pattern and play it immediately
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
    
    func removeCard(at index: Int) {
        guard index >= 0 else { return }
        
        cards.remove(at: index)
        
        if cards.isEmpty {
            isActive = false
        }
    }
    
    func pushCardToBack(at index: Int) {
        let reuseCard = cards.remove(at: index)
        cards.insert(reuseCard, at: 0)
        
        if cards.isEmpty {
            isActive = false
        }
    }
    
    func resetCards() {
        loadData()
        timeRemaining = 100
        isActive = true
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "Cards") {
            if let decoded = try? JSONDecoder().decode([Card].self, from: data) {
                self.cards = decoded
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct DefaultButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.black.opacity(0.7))
            .clipShape(Circle())
    }
}

extension View {
    func defaultButtonStyle() -> some View {
        modifier(DefaultButton())
    }
}

struct AccessibilityButton: View {
    
    var imageName: String
    var accessibilityLabel: String
    var accessibilityHint: String
    var targetAction: (() -> Void)
    
    var body: some View {
        Button(action: {
            withAnimation {
                self.targetAction()
            }
        }, label: {
            Image(systemName: imageName)
                .defaultButtonStyle()
        })
        .accessibilityLabel(Text(self.accessibilityLabel))
        .accessibility(hint: Text(self.accessibilityHint))
    }
}
