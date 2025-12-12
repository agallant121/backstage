class CreateChildren < ActiveRecord::Migration[8.0]
  def change
    create_table :children do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.date :birthday
      t.integer :age
      t.text :notes

      t.timestamps
    end
  end
end
