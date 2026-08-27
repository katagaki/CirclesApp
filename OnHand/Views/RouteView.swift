//
//  RouteView.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import SwiftUI

enum RouteDestination: Hashable {
    case buys(circleID: Int)
    case map(circleID: Int)
}

struct RouteView: View {

    @Environment(OnHandStore.self) var store

    @AppStorage(wrappedValue: 1, "OnHand.Day") var selectedDay: Int

    @State var selection: Int = 0
    @State var isColorFilterPresented: Bool = false
    @State var isMenuPresented: Bool = false

    var route: [OnHandFavorite] {
        store.favorites(on: selectedDay)
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(route.enumerated()), id: \.element.id) { index, favorite in
                RouteCard(favorite: favorite, position: index + 1, total: route.count)
                    .tag(favorite.id)
            }
        }
        .tabViewStyle(.verticalPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: RouteDestination.self) { destination in
            switch destination {
            case .buys(let circleID): CircleBuysView(circleID: circleID)
            case .map(let circleID): CircleMapView(circleID: circleID)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isColorFilterPresented = true
                } label: {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(paletteTint)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isMenuPresented = true
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $isColorFilterPresented) {
            NavigationStack {
                ColorFilterView()
            }
        }
        .sheet(isPresented: $isMenuPresented) {
            NavigationStack {
                RouteMenuView(selectedDay: $selectedDay)
            }
        }
        .onAppear {
            if selection == 0 {
                selection = (route.first(where: { !$0.isVisited }) ?? route.first)?.id ?? -1
            }
        }
        .onChange(of: selectedDay) {
            selection = route.first?.id ?? -1
        }
        .onChange(of: store.colorFilter) {
            selection = (route.first(where: { !$0.isVisited }) ?? route.first)?.id ?? -1
        }
    }

    var paletteTint: Color {
        store.colorFilter < 0 ? .accentColor : OnHandColor(value: store.colorFilter).background
    }
}

struct RouteCard: View {

    @Environment(OnHandStore.self) var store
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    let favorite: OnHandFavorite
    let position: Int
    let total: Int

    var color: OnHandColor {
        OnHandColor(value: favorite.colorValue)
    }

    var pendingItems: [OnHandBuyItem] {
        favorite.items.filter { $0.statusValue == 0 }
    }

    var body: some View {
        VStack(spacing: 0.0) {
            header

            Spacer(minLength: 0.0)

            HStack(alignment: .center, spacing: 6.0) {
                CircleCutImage(circleID: favorite.id)
                    .frame(width: 44.0)
                    .opacity(isLuminanceReduced ? 0.7 : 1.0)

                VStack(alignment: .leading, spacing: 2.0) {
                    SpaceLabel(
                        label: favorite.spaceLabel,
                        color: color,
                        fontSize: 30.0,
                        isVisited: favorite.isVisited
                    )

                    HallLabel(name: favorite.hallName, filename: favorite.hallFilename)

                    Text(favorite.circleName)
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)

                    if !isLuminanceReduced, !pendingItems.isEmpty {
                        Text("\(pendingItems.count) · ¥\(pendingItems.reduce(0) { $0 + $1.cost })")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0.0)
        }
        .padding(.horizontal, 6.0)
        .safeAreaInset(edge: .bottom, spacing: 4.0) {
            if !isLuminanceReduced {
                actions
                    .padding(.horizontal, 6.0)
            }
        }
        .containerBackground(
            color.background.gradient.opacity(isLuminanceReduced ? 0.0 : 0.16),
            for: .tabView
        )
    }

    var header: some View {
        HStack {
            Text("\(position)/\(total)")
                .font(.system(size: 12.0, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    var actions: some View {
        GlassEffectContainer(spacing: 6.0) {
            HStack(spacing: 6.0) {
                NavigationLink(value: RouteDestination.map(circleID: favorite.id)) {
                    actionLabel("map.fill")
                }
                .buttonStyle(.plain)
                .disabled(favorite.mapRect == nil)
                .opacity(favorite.mapRect == nil ? 0.4 : 1.0)
                .glassEffect(.regular.interactive(), in: .capsule)

                NavigationLink(value: RouteDestination.buys(circleID: favorite.id)) {
                    actionLabel("cart.fill")
                }
                .buttonStyle(.plain)
                .disabled(favorite.items.isEmpty)
                .opacity(favorite.items.isEmpty ? 0.4 : 1.0)
                .glassEffect(.regular.interactive(), in: .capsule)

                Button {
                    store.toggleVisited(favorite.id)
                } label: {
                    actionLabel(favorite.isVisited ? "arrow.uturn.backward" : "checkmark")
                }
                .buttonStyle(.plain)
                .glassEffect(
                    favorite.isVisited
                        ? .regular.interactive()
                        : .regular.tint(Color.accentColor).interactive(),
                    in: .capsule
                )
            }
        }
    }

    func actionLabel(_ symbolName: String) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: 17.0, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 38.0)
            .contentShape(.capsule)
    }
}

struct RouteMenuView: View {

    @Environment(OnHandStore.self) var store

    @Binding var selectedDay: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 6.0) {
                if store.payload.days.count > 1 {
                    Picker("OnHand.Day", selection: $selectedDay) {
                        ForEach(store.payload.days) { day in
                            VStack(alignment: .leading, spacing: 1.0) {
                                Text("Shared.\(day.id)th.Day")
                                Text("\(day.month)/\(day.day)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(day.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                NavigationLink {
                    BuysView()
                } label: {
                    Label("OnHand.Buys", systemImage: "cart.fill")
                }

                Text(store.payload.eventName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4.0)
            }
            .padding(.horizontal, 4.0)
        }
    }
}
