class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :total, precision: 8, scale: 2
      t.string :status, default: "pending", null: false
      t.string :stripe_session_id

      t.timestamps
    end

    add_index :orders, :stripe_session_id, unique: true
  end
end
