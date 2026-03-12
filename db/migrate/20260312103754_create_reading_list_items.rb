class CreateReadingListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :reading_list_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ebook, null: false, foreign_key: true
      t.string :status
      t.integer :current_page

      t.timestamps
    end

    add_index :reading_list_items, [:user_id, :ebook_id], unique: true
  end
end
