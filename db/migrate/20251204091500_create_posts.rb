class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.string :author_name
      t.datetime :published_at

      t.timestamps
    end
    add_index :posts, :published_at
  end
end
