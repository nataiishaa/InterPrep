//
//  OnboardingView.swift
//  InterPrep
//
//  Passive View for Onboarding screen
//

import DesignSystem
import SwiftUI

struct OnboardingView: View {
    let model: Model
    
    var body: some View {
        ZStack {
            LinearGradient.brandBackground
                .ignoresSafeArea()
            
            VStack(spacing: CGFloat.zero) {
                if !model.isLastPage {
                    HStack {
                        Spacer()
                        Button("Пропустить") {
                            model.onSkip()
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.trailing, Layout.skipButtonTrailingPadding)
                    }
                    .padding(.top, Layout.skipBarTopPadding)
                } else {
                    Color.clear.frame(height: Layout.skipBarPlaceholderHeight)
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
                
                VStack(spacing: Layout.footerStackSpacing) {
                    if model.isLastPage {
                        Button {
                            model.onGetStarted()
                        } label: {
                            Text("Начать")
                                .font(.headline)
                                .foregroundColor(.buttonText)
                                .frame(maxWidth: Layout.primaryButtonMaxWidth)
                                .padding(.vertical, Layout.primaryButtonVerticalPadding)
                                .background(Color.buttonBackground)
                                .cornerRadius(Layout.primaryButtonCornerRadius)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Button {
                            model.onNext()
                        } label: {
                            Text("Далее")
                                .font(.headline)
                                .foregroundColor(.buttonText)
                                .frame(maxWidth: Layout.primaryButtonMaxWidth)
                                .padding(.vertical, Layout.primaryButtonVerticalPadding)
                                .background(Color.buttonBackground)
                                .cornerRadius(Layout.primaryButtonCornerRadius)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Button("Зарегистрироваться") {
                        model.onRegister()
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, Layout.registerLinkBottomPadding)
                }
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: Layout.footerAnimationDuration), value: model.isLastPage)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingView.Model.PageModel
    @State private var imageScale: CGFloat = Layout.imageScaleInitial
    @State private var imageOpacity: Double = Layout.imageOpacityInitial
    @State private var textOffset: CGFloat = Layout.textOffsetInitial
    @State private var textOpacity: Double = Layout.textOpacityInitial
    
    var body: some View {
        VStack(spacing: Layout.pageStackSpacing) {
            Spacer()
            
            Image(systemName: page.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: Layout.heroImageSide, height: Layout.heroImageSide)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(imageScale)
                .opacity(imageOpacity)
                .shadow(color: .black.opacity(0.2), radius: Layout.heroShadowRadius, x: .zero, y: Layout.heroShadowY)
            
            Spacer()
                .frame(height: Layout.heroToTextSpacerHeight)
            
            VStack(spacing: Layout.textBlockSpacing) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Layout.textHorizontalPadding)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Layout.textHorizontalPadding)
            }
            .offset(y: textOffset)
            .opacity(textOpacity)
            
            Spacer()
        }
        .task {
            withAnimation(
                .spring(response: Layout.imageSpringResponse, dampingFraction: Layout.imageSpringDamping)
            ) {
                imageScale = Layout.imageScaleFinal
                imageOpacity = Layout.imageOpacityFinal
            }
            
            withAnimation(
                .easeOut(duration: Layout.textAnimationDuration).delay(Layout.textAnimationDelay)
            ) {
                textOffset = CGFloat.zero
                textOpacity = Layout.textOpacityFinal
            }
        }
    }
}

extension OnboardingView {
    enum Layout {
        static let skipButtonTrailingPadding: CGFloat = 24
        static let skipBarTopPadding: CGFloat = 8
        static let skipBarPlaceholderHeight: CGFloat = 40
        static let footerStackSpacing: CGFloat = 16
        static let primaryButtonMaxWidth: CGFloat = 280
        static let primaryButtonVerticalPadding: CGFloat = 16
        static let primaryButtonCornerRadius: CGFloat = 12
        static let registerLinkBottomPadding: CGFloat = 20
        static let footerAnimationDuration: Double = 0.3
    }
}

extension OnboardingPageView {
    enum Layout {
        static let pageStackSpacing: CGFloat = 32
        static let heroImageSide: CGFloat = 200
        static let heroShadowRadius: CGFloat = 20
        static let heroShadowY: CGFloat = 10
        static let heroToTextSpacerHeight: CGFloat = 40
        static let textBlockSpacing: CGFloat = 16
        static let textHorizontalPadding: CGFloat = 40
        static let imageScaleInitial: CGFloat = 0.8
        static let imageScaleFinal: CGFloat = 1.0
        static let imageOpacityInitial: Double = .zero
        static let textOpacityInitial: Double = .zero
        static let imageOpacityFinal: Double = 1.0
        static let textOpacityFinal: Double = 1.0
        static let textOffsetInitial: CGFloat = 50
        static let imageSpringResponse: Double = 0.6
        static let imageSpringDamping: Double = 0.7
        static let textAnimationDuration: Double = 0.5
        static let textAnimationDelay: Double = 0.2
    }
}

#Preview("First Page") {
    OnboardingView(model: .fixture)
}

#Preview("Last Page") {
    OnboardingView(model: .lastPageFixture)
}
