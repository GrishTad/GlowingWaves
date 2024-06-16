//
//  ContentView.swift
//  GlowingWaves
//
//  Created by Grisha Tadevosyan on 16.06.24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader{ geo in
            VStack{
                Spacer()
                MetalView()
                
                
            }.frame(width: geo.size.width, height: geo.size.height)
        }.edgesIgnoringSafeArea(.all)
    }
}

