//
//  ThemePreview.swift
//  InterPrep
//
//  Theme preview for testing dark mode
//

import SwiftUI

#if DEBUG
struct ThemePreviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Демонстрация темной темы")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textOnBackground)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Цвета")
                        .font(.headline)
                        .foregroundColor(.textOnBackground)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ColorSwatch(name: "Brand Primary", color: .brandPrimary)
                        ColorSwatch(name: "Brand Secondary", color: .brandSecondary)
                        ColorSwatch(name: "Card Background", color: .cardBackground)
                        ColorSwatch(name: "Field Background", color: .fieldBackground)
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Стили текста")
                        .font(.headline)
                        .foregroundColor(.textOnBackground)
                    
                    Text("Primary Text")
                        .foregroundColor(.textPrimary)
                    
                    Text("Secondary Text")
                        .foregroundColor(.textSecondary)
                    
                    Text("Tertiary Text")
                        .foregroundColor(.textTertiary)
                    
                    Text("Text on Background")
                        .foregroundColor(.textOnBackground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Buttons
                VStack(spacing: 12) {
                    Text("Кнопки")
                        .font(.headline)
                        .foregroundColor(.textOnBackground)
                    
                    Button("Primary Button") {}
                        .buttonStyle(.borderedProminent)
                        .tint(.brandPrimary)
                    
                    Button("Secondary Button") {}
                        .buttonStyle(.bordered)
                        .tint(.brandSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Cards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Карточки")
                        .font(.headline)
                        .foregroundColor(.textOnBackground)
                    
                    HStack {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .font(.largeTitle)
                                .foregroundColor(.brandPrimary)
                            
                            Text("Документы")
                                .font(.caption)
                                .foregroundColor(.textOnBackground)
                            
                            Text("12 файлов")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            
                            Text("События")
                                .font(.caption)
                                .foregroundColor(.textOnBackground)
                            
                            Text("5 встреч")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color.backgroundPrimary)
    }
}

struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.textOnBackground)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview("Light Mode") {
    ThemePreviewView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ThemePreviewView()
        .preferredColorScheme(.dark)
}
#endif
