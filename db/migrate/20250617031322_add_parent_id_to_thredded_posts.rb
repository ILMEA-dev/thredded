class AddParentIdToThreddedPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :thredded_posts, :parent_id, :integer
    add_foreign_key :thredded_posts, column: :parent_id, on_delete: :cascade
    add_index :thredded_posts, :parent_id
  end
end
