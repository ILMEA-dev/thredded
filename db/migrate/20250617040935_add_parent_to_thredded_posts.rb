class AddParentToThreddedPosts < ActiveRecord::Migration[7.0]
  def change
    add_reference :thredded_posts, :parent, null: false, foreign_key: true
  end
end
