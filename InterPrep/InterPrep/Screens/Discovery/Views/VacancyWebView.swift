//
//  VacancyWebView.swift
//  InterPrep
//
//

import SwiftUI
import WebKit

public struct VacancyWebView: View {
    let url: URL
    let title: String
    let vacancyId: String?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    
    public init(url: URL, title: String, vacancyId: String? = nil) {
        self.url = url
        self.title = title
        self.vacancyId = vacancyId
    }
    
    public var body: some View {
        ZStack {
            WebViewRepresentable(
                url: url,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward
            )
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    NotificationCenter.default.post(name: .webViewGoBack, object: nil)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoBack)
                
                Spacer()
                
                Button {
                    NotificationCenter.default.post(name: .webViewGoForward, object: nil)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)
                
                Spacer()
                
                Button {
                    NotificationCenter.default.post(name: .webViewReload, object: nil)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                
                Spacer()
                
                Button {
                    if let url = URL(string: url.absoluteString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "safari")
                }
            }
        }
    }
}

// MARK: - WebView Representable

private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        context.coordinator.setupNotifications(for: webView)
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        private var observers: [NSObjectProtocol] = []
        
        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }
        
        func setupNotifications(for webView: WKWebView) {
            let goBackObserver = NotificationCenter.default.addObserver(
                forName: .webViewGoBack,
                object: nil,
                queue: .main
            ) { _ in
                if webView.canGoBack {
                    webView.goBack()
                }
            }
            
            let goForwardObserver = NotificationCenter.default.addObserver(
                forName: .webViewGoForward,
                object: nil,
                queue: .main
            ) { _ in
                if webView.canGoForward {
                    webView.goForward()
                }
            }
            
            let reloadObserver = NotificationCenter.default.addObserver(
                forName: .webViewReload,
                object: nil,
                queue: .main
            ) { _ in
                webView.reload()
            }
            
            observers = [goBackObserver, goForwardObserver, reloadObserver]
        }
        
        deinit {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

// MARK: - Notification Names

private extension Notification.Name {
    static let webViewGoBack = Notification.Name("webViewGoBack")
    static let webViewGoForward = Notification.Name("webViewGoForward")
    static let webViewReload = Notification.Name("webViewReload")
}

// MARK: - Preview

#Preview {
    NavigationView {
        VacancyWebView(
            url: URL(string: "https://hh.ru/vacancy/123456")!,
            title: "iOS Developer"
        )
    }
}
