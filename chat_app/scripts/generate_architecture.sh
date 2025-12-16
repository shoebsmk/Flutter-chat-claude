#!/bin/bash

# Script to generate architecture diagrams from code
# This generates structural diagrams that can be updated automatically
# Note: Conceptual diagrams (flows, sequences) still need manual updates

echo "Generating architecture diagrams..."

# Check if dart is available
if ! command -v dart &> /dev/null; then
    echo "Error: Dart is not installed or not in PATH"
    exit 1
fi

# Create output directory
mkdir -p docs/generated

# Option 1: Using LayerLens (if installed)
# Run: dart pub global activate layerlens
# Then: layerlens lib > docs/generated/layer_structure.mmd

# Option 2: Generate simple dependency structure
echo "Generating project structure diagram..."

cat > docs/generated/project_structure.mmd << 'EOF'
```mermaid
graph TD
    subgraph "lib/"
        Main[main.dart]
        
        subgraph "config/"
            SupabaseConfig[supabase_config.dart]
        end
        
        subgraph "models/"
            UserModel[user.dart]
            MessageModel[message.dart]
        end
        
        subgraph "services/"
            AuthService[auth_service.dart]
            ChatService[chat_service.dart]
            UserService[user_service.dart]
        end
        
        subgraph "screens/"
            AuthScreen[auth_screen.dart]
            ChatListScreen[chat_list_screen.dart]
            ChatScreen[chat_screen.dart]
        end
        
        subgraph "widgets/"
            MessageBubble[message_bubble.dart]
            UserAvatar[user_avatar.dart]
            MessageInput[message_input.dart]
            LoadingShimmer[loading_shimmer.dart]
        end
        
        subgraph "utils/"
            Constants[constants.dart]
            DateUtils[date_utils.dart]
        end
        
        subgraph "exceptions/"
            AppExceptions[app_exceptions.dart]
        end
        
        subgraph "theme/"
            AppTheme[app_theme.dart]
        end
    end
    
    Main --> SupabaseConfig
    Main --> AuthScreen
    Main --> ChatListScreen
    Main --> AuthService
    Main --> AppTheme
    
    AuthScreen --> AuthService
    AuthScreen --> ChatListScreen
    
    ChatListScreen --> ChatScreen
    ChatListScreen --> UserService
    ChatListScreen --> ChatService
    ChatListScreen --> UserAvatar
    ChatListScreen --> LoadingShimmer
    
    ChatScreen --> ChatService
    ChatScreen --> MessageBubble
    ChatScreen --> MessageInput
    ChatScreen --> UserAvatar
    
    AuthService --> UserModel
    ChatService --> MessageModel
    UserService --> UserModel
    
    AuthService --> SupabaseConfig
    ChatService --> SupabaseConfig
    UserService --> SupabaseConfig
    
    MessageBubble --> MessageModel
    MessageInput --> ChatService
    UserAvatar --> UserModel
```
EOF

echo "Generated diagrams saved to docs/generated/"
echo ""
echo "To view the diagrams:"
echo "1. Open docs/generated/project_structure.mmd"
echo "2. Copy the mermaid code to any Mermaid viewer (GitHub, GitLab, mermaid.live)"
echo ""
echo "To integrate with ARCHITECTURE.md, you can:"
echo "1. Manually copy relevant diagrams"
echo "2. Or include them with: ![](docs/generated/project_structure.mmd)"





