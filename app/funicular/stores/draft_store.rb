module Funicular
  module DraftStore
    @kvs = nil
    @disabled = false

    def self.init!
      @kvs ||= IndexedDB::KVS.open('funicular_drafts')
    end

    def self.get(channel_id)
      return nil unless @kvs && !@disabled && channel_id
      @kvs["draft:channel:#{channel_id}"]
    end

    def self.set(channel_id, text)
      return unless @kvs && !@disabled && channel_id
      key = "draft:channel:#{channel_id}"
      text.to_s.empty? ? @kvs.delete(key) : @kvs[key] = text
    end

    def self.delete(channel_id)
      return unless @kvs && channel_id
      @kvs.delete("draft:channel:#{channel_id}")
    end

    def self.clear_all!
      @kvs&.clear
      @disabled = true
    end

    def self.enable!
      @disabled = false
    end

    def self.disabled?
      @disabled
    end
  end
end
