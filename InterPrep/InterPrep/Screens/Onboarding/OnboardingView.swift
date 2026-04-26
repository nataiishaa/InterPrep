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
                    }
                    
                    Button("Зарегистрироваться") {
                        model.onRegister()
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, Layout.registerLinkBottomPadding)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingView.Model.PageModel
    
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
            
            Spacer()
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
    }
}

#Preview("First Page") {
    OnboardingView(model: .fixture)
}

#Preview("Last Page") {
    OnboardingView(model: .lastPageFixture)
}
