class AddIsCustomToUrls < ActiveRecord::Migration[7.1]
  def change
    add_column :urls, :is_custom, :boolean
  end
end
