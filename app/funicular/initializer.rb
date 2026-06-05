puts "Funicular Chat App initializing..."

# Configure debug highlighter color
Funicular.debug_color = "pink"  # Options: "green", "yellow", "pink", "cyan", or nil to disable

# Mount JavaScript helpers
Funicular::FileUpload.mount

# Initialize draft store (defined in stores/draft_store.rb).
# Skipped on the server (SSR): IndexedDB is a browser-only API.
Funicular::DraftStore.init! unless Funicular.server?

# Load all model schemas before starting the app
Funicular.load_schemas({ User => "user", Session => "session", Channel => "channel", Post => "post", Comment => "comment" }) do
  # Start the application after all schemas are loaded
  Funicular.start(container: 'app') do |router|
    # Public, server-rendered tech blog (SSR + hydration demo).
    router.get('/blog', to: BlogIndexComponent, as: 'blog')
    router.get('/blog/:id', to: BlogPostComponent, as: 'blog_post', constraints: { id: /\d+/ })
    router.get('/login', to: LoginComponent, as: 'login')
    router.get('/chat/:channel_id', to: ChatComponent, as: 'chat_channel', constraints: { channel_id: /\d+/ })
    router.get('/chat', to: ChatComponent, as: 'chat')
    router.get('/settings', to: SettingsComponent, as: 'settings')
    router.delete('/messages/:message_id', to: MessageComponent, as: 'message', constraints: { message_id: /\d+/ })
    router.set_default('/login')
  end
end
