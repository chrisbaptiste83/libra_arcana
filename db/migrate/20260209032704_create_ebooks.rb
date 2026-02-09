class CreateEbooks < ActiveRecord::Migration[8.0]
  def change
    create_table :ebooks do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.decimal :price, precision: 8, scale: 2, null: false
      t.text :description
      t.integer :page_count
      t.string :isbn
      t.string :language, default: "English"
      t.integer :publication_year
      t.boolean :featured, default: false, null: false
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
