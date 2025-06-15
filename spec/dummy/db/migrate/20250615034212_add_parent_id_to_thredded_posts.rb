class AddParentIdToThreddedPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :thredded_posts, :parent_id, :integer
  end
end
