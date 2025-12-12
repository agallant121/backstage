class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :birthday, :date
    add_column :users, :spouse_name, :string
    add_column :users, :spouse_birthday, :date
    add_column :users, :home_address, :text
    add_column :users, :contact_notes, :text
  end
end
