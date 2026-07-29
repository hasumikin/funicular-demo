# Per-channel message drafts, kept only in the browser's local database
# (never sent to the server). Replaces the old hand-rolled DraftStore:
# rows live in SQLite, snapshots persist through the framework, and the
# user_key namespace isolates drafts between accounts on a shared
# machine -- no manual clear-on-logout needed.
class Draft < Funicular::Model
  storage :local do
    migrate 1 do |t|
      t.integer :channel_id, null: false
      t.text :body
      t.timestamps
      t.index :channel_id
    end
  end

  def self.for_channel(channel_id)
    return nil unless channel_id
    local.find_by(channel_id: channel_id)
  end

  # Upsert the draft for a channel; an empty body deletes it. Writes
  # raise ReadOnlyTabError on a reader tab (another tab holds the
  # writer lock) -- callers decide whether that matters.
  def self.store(channel_id, body)
    return unless channel_id
    draft = for_channel(channel_id)
    text = body.to_s
    if text.empty?
      draft&.destroy
    elsif draft
      draft.update(body: text)
    else
      create(channel_id: channel_id, body: text)
    end
    nil
  end

  def self.discard(channel_id)
    return unless channel_id
    for_channel(channel_id)&.destroy
    nil
  end
end
