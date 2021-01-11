//
//  ContentView.swift
//  Shared
//
//  Created by Brad Howes on 11/1/21.
//

import SwiftUI

struct ContentView: View {
    @State var alpha: CGFloat = 0.0
    @State var beta: CGFloat = 0.0
    @State var delta: CGFloat = 0.0
    @State var gamma: CGFloat = 0.0

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top) {
                VStack {
                    Text("Column 1")
                    KnobView(label: "Alpha", value: $alpha).border(Color.yellow)
                    KnobView(label: "Beta", value: $beta).border(Color.yellow)
                    KnobView(label: "Delta", value: $delta).border(Color.yellow)
                    KnobView(label: "Gamma", value: $gamma).border(Color.yellow)
                }
                .border(Color.white)
                VStack {
                    Text("Column 2")
                    KnobView(label: "Alpha", value: $alpha).border(Color.yellow)
                    KnobView(label: "Beta", value: $beta).border(Color.yellow)
                }
                .border(Color.white)
                VStack {
                    Text("Column 3")
                    KnobView(label: "Alpha", value: $alpha).border(Color.yellow)
                    KnobView(label: "Beta", value: $beta).border(Color.yellow)
                    KnobView(label: "Delta", value: $delta).border(Color.yellow)
                }
                .border(Color.white)
                VStack {
                    Text("Column 4")
                    KnobView(label: "Alpha", value: $alpha).border(Color.yellow)
                    KnobView(label: "Beta", value: $beta).border(Color.yellow)
                    KnobView(label: "Delta", value: $delta).border(Color.yellow)
                    KnobView(label: "Gamma", value: $gamma).border(Color.yellow)
                }
                .border(Color.white)
            }
            .padding()
            .border(Color.green)
        }
        .background(Color.black)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
