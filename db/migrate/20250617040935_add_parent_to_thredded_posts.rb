class AddParentToThreddedPosts < ActiveRecord::Migration[7.0]
  def change
    add_reference :thredded_posts, :parent, foreign_key: { to_table: :thredded_posts }, null: true
  end
end
