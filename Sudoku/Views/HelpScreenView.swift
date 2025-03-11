import SwiftUI

struct HelpScreenView: View {
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Label("Information", systemImage: "")
                        .font(.title)
                        .bold(true)
                        .foregroundColor(.primary)
                        .offset(y: -50)
                        .padding(.top, 50)
                    Label("Archipelago Breakdown:", systemImage: "")
                        .font(.title2)
                        .bold(true)
                        .foregroundColor(.primary)
                        .offset(y: -50)
                    Text("Archipelago is an open source multi-world game randomizer.  With it, you can randomize items in games into other games, making a fun challenge for yourself and others to complete cooperatively or competitively.  More information can be found at: \nhttps://archipelago.gg")
                        .font(.title3)
                        .offset(y: -50)
                        .padding(.horizontal, 20)
                    Text("This app is a recreation of an open source Godot project called APSudoku.  You can find it here: \nhttps://github.com/APSudoku/APSudoku \nThe point of this app is to be able to get hints for which items are at which locations in your game.")
                        .font(.title3)
                        .offset(y: -50)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    VStack {
                        Text("Difficulty hint percentages:")
                            .font(.title2)
                        HStack {
                            VStack (alignment: .leading) {
                                Text("Easy:")
                                    .foregroundColor(Color(.sRGB, red: 144/255, green: 208/255, blue: 144/255))
                                    .padding(.horizontal, 3)
                                Text("Medium:")
                                    .foregroundColor(Color(.sRGB, red: 236/255, green: 228/255, blue: 148/255))
                                    .padding(.horizontal, 3)
                                Text("Hard:")
                                    .foregroundColor(Color(.sRGB, red: 220/255, green: 164/255, blue: 124/255))
                                    .padding(.horizontal, 3)
                                Text("Killer:")
                                    .foregroundColor(Color(.sRGB, red: 204/255, green: 115/255, blue: 131/255))
                                    .padding(.horizontal, 3)
                            }
                            VStack {
                                Text(HintGameWebSocketClient.hintProbabilitiesString(for: "Easy"))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(Color(.sRGB, red: 144/255, green: 208/255, blue: 144/255))
                                Text(HintGameWebSocketClient.hintProbabilitiesString(for: "Medium"))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(Color(.sRGB, red: 236/255, green: 228/255, blue: 148/255))
                                Text(HintGameWebSocketClient.hintProbabilitiesString(for: "Hard"))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(Color(.sRGB, red: 220/255, green: 164/255, blue: 124/255))
                                Text(HintGameWebSocketClient.hintProbabilitiesString(for: "Killer"))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(Color(.sRGB, red: 204/255, green: 115/255, blue: 131/255))
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HelpScreenView()
}
