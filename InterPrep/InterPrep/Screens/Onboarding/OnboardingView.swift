//
//  OnboardingView.swift
//  InterPrep
//
//  Passive View for Onboarding screen
//

import SwiftUI

struct OnboardingView: View {
    let model: Model
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.5, blue: 0.45),
                    Color(red: 0.35, green: 0.4, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if !model.isLastPage {
                    HStack {
                        Spacer()
                        Button("Пропустить") {
                            model.onSkip()
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                    }
                } else {
                    Color.clear.frame(height: 60)
                }
                
                TabView(selection: Binding(
                    get: { model.currentPage },
                    set: { model.onPageChanged($0) }
                )) {
                    ForEach(model.pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                VStack(spacing: 16) {
                    if model.isLastPage {
                        Button {
                            model.onGetStarted()
                        } label: {
                            Text("Начать")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.35))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Button {
                            model.onNext()
                        } label: {
                            Text("Далее")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.35))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Button("Зарегистрироваться") {
                        model.onRegister()
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 20)
                }
                .animation(.easeInOut(duration: 0.3), value: model.isLastPage)
            }
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingView.Model.PageModel
    @State private var imageScale: CGFloat = 0.8
    @State private var imageOpacity: Double = 0
    @State private var textOffset: CGFloat = 50
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: page.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(imageScale)
                .opacity(imageOpacity)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .offset(y: textOffset)
            .opacity(textOpacity)
            
            Spacer()
        }
        .task {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                imageScale = 1.0
                imageOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                textOffset = 0
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Presentation Model

extension OnboardingView {
    struct Model {
        let currentPage: Int
        let pages: [PageModel]
        let isLastPage: Bool
        let onNext: () -> Void
        let onPrevious: () -> Void
        let onPageChanged: (Int) -> Void
        let onSkip: () -> Void
        let onGetStarted: () -> Void
        let onRegister: () -> Void
        
        struct PageModel: Identifiable {
            let id: Int
            let imageName: String
            let title: String
            let description: String
        }
    }
}

// MARK: - Fixtures

#if DEBUG
extension OnboardingView.Model {
    static var fixture: Self {
        .init(
            currentPage: 0,
            pages: [
                .init(
                    id: 0,
                    imageName: "video.circle.fill",
                    title: "Ищите работу в пару кликов",
                    description: "Не тратьте время на просмотр неинтересных для вас вакансий"
                ),
                .init(
                    id: 1,
                    imageName: "calendar.circle.fill",
                    title: "Планируйте собеседования",
                    description: "Календарь и материалы для подготовки. Все в одном приложении."
                ),
                .init(
                    id: 2,
                    imageName: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Прокачивайте карьеру",
                    description: "Карьерный консунтант подскажет, что улучшить в навыках и куда расти дальше"
                )
            ],
            isLastPage: false,
            onNext: {},
            onPrevious: {},
            onPageChanged: { _ in },
            onSkip: {},
            onGetStarted: {},
            onRegister: {}
        )
    }
    
    static var lastPageFixture: Self {
        .init(
            currentPage: 2,
            pages: [
                .init(
                    id: 0,
                    imageName: "video.circle.fill",
                    title: "Ищите работу в пару кликов",
                    description: "Не тратьте время на просмотр неинтересных для вас вакансий"
                ),
                .init(
                    id: 1,
                    imageName: "calendar.circle.fill",
                    title: "Планируйте собеседования",
                    description: "Календарь и материалы для подготовки. Все в одном приложении."
                ),
                .init(
                    id: 2,
                    imageName: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Прокачивайте карьеру",
                    description: "Карьерный консунтант подскажет, что улучшить в навыках и куда расти дальше"
                )
            ],
            isLastPage: true,
            onNext: {},
            onPrevious: {},
            onPageChanged: { _ in },
            onSkip: {},
            onGetStarted: {},
            onRegister: {}
        )
    }
}
#endif

// MARK: - Previews

#Preview("First Page") {
    OnboardingView(model: .fixture)
}

#Preview("Last Page") {
    OnboardingView(model: .lastPageFixture)
}
