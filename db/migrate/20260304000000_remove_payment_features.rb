class RemovePaymentFeatures < ActiveRecord::Migration[8.0]
  def change
    remove_column :ebooks, :price, :decimal

    drop_table :download_accesses
    drop_table :order_items
    drop_table :payments
    drop_table :orders
  end
end
