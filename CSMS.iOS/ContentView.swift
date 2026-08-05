import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: SupabaseManager
    
    @State private var rooms: [CSMSChatRoom] = []
    @State private var isLoading = false
    @State private var showCreateGroup = false
    @State private var newGroupName = ""
    @State private var selectedRoom: CSMSChatRoom? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.02, green: 0.04, blue: 0.06).ignoresSafeArea()
                
                VStack {
                    if isLoading && rooms.isEmpty {
                        ProgressView("Cargando salas CSMS...")
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.purple))
                    } else {
                        List {
                            ForEach(rooms) { room in
                                NavigationLink(destination: ConversationView(room: room)) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.purple.opacity(0.3))
                                                .frame(width: 44, height: 44)
                                                .overlay(Circle().stroke(Color.purple, lineWidth: 1.2))
                                            Text(room.displayName.prefix(2).uppercased())
                                                .font(.system(size: 15, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(room.displayName)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.white)
                                            Text(room.is_group == true ? "Grupo de Chat CSMS" : "Mensaje Directo")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color(red: 0.12, green: 0.16, blue: 0.23).opacity(0.85))
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("CSMS iOS")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                NavigationView {
                    Form {
                        Section(header: Text("Nombre del Grupo CSMS")) {
                            TextField("Ej: Hackers Cota", text: $newGroupName)
                        }
                        Button("Crear Grupo") {
                            guard !newGroupName.isEmpty else { return }
                            Task {
                                _ = try? await manager.createGroupChat(name: newGroupName)
                                newGroupName = ""
                                showCreateGroup = false
                                await loadRooms()
                            }
                        }
                        .foregroundColor(.purple)
                    }
                    .navigationTitle("Nuevo Grupo")
                }
            }
            .onAppear {
                Task {
                    await loadRooms()
                }
            }
        }
    }
    
    private func loadRooms() async {
        isLoading = true
        if let list = try? await manager.fetchChatRooms() {
            self.rooms = list
        }
        isLoading = false
    }
}

struct ConversationView: View {
    @EnvironmentObject var manager: SupabaseManager
    let room: CSMSChatRoom
    
    @State private var messages: [CSMSChatMessage] = []
    @State private var typedText = ""
    @State private var timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(messages) { msg in
                        let isMine = msg.sender_id == "my-user"
                        HStack {
                            if isMine { Spacer() }
                            Text(msg.content)
                                .font(.system(size: 14))
                                .padding(12)
                                .background(isMine ? Color.purple : Color(red: 0.12, green: 0.16, blue: 0.23))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            if !isMine { Spacer() }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            
            HStack(spacing: 8) {
                TextField("Escribe un mensaje CSMS...", text: $typedText)
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.purple)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color(red: 0.06, green: 0.09, blue: 0.16))
        }
        .background(Color(red: 0.02, green: 0.04, blue: 0.06).ignoresSafeArea())
        .navigationTitle(room.displayName)
        .onAppear {
            Task { await loadMessages() }
        }
        .onReceive(timer) { _ in
            Task { await loadMessages() }
        }
    }
    
    private func loadMessages() async {
        if let list = try? await manager.fetchChatMessages(roomId: room.id) {
            self.messages = list
        }
    }
    
    private func sendMessage() {
        let text = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        typedText = ""
        Task {
            _ = try? await manager.sendMessage(roomId: room.id, content: text)
            await loadMessages()
        }
    }
}
