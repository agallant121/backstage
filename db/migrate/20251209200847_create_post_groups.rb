class CreatePostGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :post_groups do |t|
      t.references :post, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end

    add_index :post_groups, [ :post_id, :group_id ], unique: true
  end
end
