//
//  ChatListView.swift
//  InterPrep
//
//  Chat list view (for future multiple chats)
//

import SwiftUI

struct ChatListView: View {
    let chats: [ChatPreview]
    let onChatTap: (ChatPreview) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(chats) { chat in
                    ChatPreviewRow(chat: chat)
                        .onTapGesture {
                            onChatTap(chat)
                        }
                }
            }
            .navigationTitle("Сообщения")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}



struct ChatPreview: Identifiable {
    let id: UUID
    let consultant: Consultant
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
    
    init(
        id: UUID = UUID(),
        consultant: Consultant,
        lastMessage: String,
        lastMessageTime: Date,
        unreadCount: Int = 0
    ) {
        self.id = id
        self.consultant = consultant
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
    }
}



struct ChatPreviewRow: View {
    let chat: ChatPreview
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(chat.consultant.name.prefix(1))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
                .overlay(
                    Circle()
                        .fill(chat.consultant.isOnline ? Color.green : Color.clear)
                        .frame(width: 12, height: 12)
                        .offset(x: 18, y: 18)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.consultant.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(chat.lastMessageTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(chat.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}



#Preview {
    ChatListView(
        chats: [
            ChatPreview(
                consultant: Consultant(
                    name: "Анна Петрова",
                    title: "Карьерный консультант",
                    isOnline: true
                ),
                lastMessage: "Отлично! Давайте начнем с того...",
                lastMessageTime: Date().addingTimeInterval(-300),
                unreadCount: 2
            ),
            ChatPreview(
                consultant: Consultant(
                    name: "Иван Иванов",
                    title: "HR специалист",
                    isOnline: false
                ),
                lastMessage: "Спасибо за информацию!",
                lastMessageTime: Date().addingTimeInterval(-3600),
                unreadCount: 0
            )
        ],
        onChatTap: { _ in }
    )
}
