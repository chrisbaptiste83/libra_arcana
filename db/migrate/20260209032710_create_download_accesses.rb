class CreateDownloadAccesses < ActiveRecord::Migration[8.0]
  def change
    create_table :download_accesses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ebook, null: false, foreign_key: true
      t.references :order, foreign_key: true
      t.string :access_token, null: false
      t.datetime :expires_at, null: false
      t.integer :download_count, default: 0, null: false

      t.timestamps
    end

    add_index :download_accesses, :access_token, unique: true
  end
end
