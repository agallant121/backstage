class RenamePartnerFieldsToSpouse < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:users, :partner_name) && !column_exists?(:users, :spouse_name)
      rename_column :users, :partner_name, :spouse_name
    end

    if column_exists?(:users, :partner_birthday) && !column_exists?(:users, :spouse_birthday)
      rename_column :users, :partner_birthday, :spouse_birthday
    end
  end
end
