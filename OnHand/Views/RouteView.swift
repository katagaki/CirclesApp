//
//  RouteView.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import SwiftUI

struct RouteView: View {

    @Environment(OnHandStore.self) var store

    @AppStorage(wrappedValue: 1, "OnHand.Day") var selectedDay: Int

    @State var selection: Int = 0

    var route: [OnHandFavorite] {
        store.favorites(on: selectedDay)
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(route.enumerated()), id: \.element.id) { index, favorite in
                RouteCard(favorite: favorite, position: index + 1, total: route.count)
                    .tag(favorite.id)
            }
            RouteMenuPage(selectedDay: $selectedDay)
                .tag(-1)
        }
        .tabViewStyle(.verticalPage)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if selection == 0 {
                selection = (route.first(where: { !$0.isVisited }) ?? route.first)?.id ?? -1
            }
        }
        .onChange(of: selectedDay) {
            selection = route.first?.id ?? -1
        }
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

            SpacePill(
                label: favorite.spaceLabel,
                color: color,
                fontSize: 42.0,
                isVisited: favorite.isVisited
            )

            Text(favorite.hallName)
                .font(.system(.headline, design: .rounded))

            if !isLuminanceReduced {
                Text(favorite.circleName)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)

                if !pendingItems.isEmpty {
                    Text("\(pendingItems.count) · ¥\(pendingItems.reduce(0) { $0 + $1.cost })")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 1.0)
                }
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
            if favorite.isVisited {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12.0))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    var actions: some View {
        GlassEffectContainer(spacing: 6.0) {
            HStack(spacing: 6.0) {
                NavigationLink(value: favorite) {
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
        .navigationDestination(for: OnHandFavorite.self) { favorite in
            CircleBuysView(circleID: favorite.id)
        }
    }

    func actionLabel(_ symbolName: String) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: 20.0, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 42.0)
            .contentShape(.capsule)
    }
}

struct RouteMenuPage: View {

    @Environment(OnHandStore.self) var store

    @Binding var selectedDay: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 6.0) {
                let route = store.favorites(on: selectedDay)
                Text("\(route.filter { $0.isVisited }.count) / \(route.count)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("OnHand.Visited")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if store.payload.days.count > 1 {
                    Picker("OnHand.Day", selection: $selectedDay) {
                        ForEach(store.payload.days) { day in
                            Text("\(day.month)/\(day.day)").tag(day.id)
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
