//
//  ContentView.swift
//  SmoothTransitions
//
//  Created by Chris Eidhof on 19.05.21.
//

import SwiftUI

extension CGSize {
    static func /(lhs: Self, rhs: CGFloat) -> Self {
        CGSize(width: lhs.width/rhs, height: lhs.height/rhs)
    }
    
    static func *(lhs: Self, rhs: CGFloat) -> Self {
        CGSize(width: lhs.width*rhs, height: lhs.height*rhs)
    }
    
    static func -(lhs: Self, rhs: Self) -> Self {
        CGSize(width: lhs.width-rhs.width, height: lhs.height-rhs.height)
    }
    
    static func +(lhs: Self, rhs: Self) -> Self {
        CGSize(width: lhs.width+rhs.width, height: lhs.height+rhs.height)
    }
}

struct Item: Identifiable {
    var id = UUID()
    var color = Color(hue: .random(in: 0...1), saturation: 0.9, brightness: 0.9)
}

struct CardView: View {
    var item: Item
    
    var body: some View {
        Text("Hello, World!")
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
            )
    }
}

struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize?
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        value = value ?? nextValue()
    }
}

extension View {
    func measure() -> some View {
        background(GeometryReader { proxy in
            Color.clear.preference(key: SizeKey.self, value: proxy.size)
        })
    }
}

struct ContentView: View {
    let items = (0...3).map { _ in Item() }
    @State var magnification: CGFloat = 1
    @State var currentID: Item.ID? = nil
    @State var endSize: CGSize = .zero
    @State var fullScreen = false
    let cardSize = CGSize(width: 80, height: 100)
    
    var currentItem: Item? {
        items.first { $0.id == currentID }
    }
    
    var factor: CGFloat {
        (magnification-1)/2
    }
    
    func size(for id: Item.ID) -> CGSize {
        guard id == currentID else { return cardSize }
        let size = cardSize + (endSize - cardSize) * factor
        return CGSize(width: max(0, size.width), height: max(0, size.height))
    }
    
    @Namespace var ns
    
    var animation: Animation = .easeInOut(duration: 3)
    
    var body: some View {
        ZStack {
            HStack {
                ForEach(items) { item in
                    let s = size(for: item.id)
                    let shouldHide = fullScreen && currentID == item.id
                    VStack {
                        if !shouldHide {
                            CardView(item: item)
                                .matchedGeometryEffect(id: item.id, in: ns)
                                .frame(width: s.width, height: s.height)
                        }
                    }
                    .frame(width: cardSize.width, height: cardSize.height)
                    .zIndex(item.id == currentID ? 2 : 1)
                    .gesture(
                        MagnificationGesture()
                            .onChanged {
                                currentID = item.id
                                magnification = $0
                            }
                            .onEnded { _ in
                                withAnimation(animation) {
                                    fullScreen = true
                                }
                                magnification = 1
                            }
                    )
                }
            }
            Color.clear.measure().onPreferenceChange(SizeKey.self, perform: { value in
                endSize = value ?? .zero
            })
            if let item = currentItem, fullScreen {
                CardView(item: item)
                    .matchedGeometryEffect(id: item.id, in: ns)
                    .onTapGesture {
                        fullScreen = false
                    }
                    .transition(.identity)
            }
        }
        .padding(50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
