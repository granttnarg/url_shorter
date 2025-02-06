class AddTitleDescriptionToUrl < ActiveRecord::Migration[7.1]
  def change
    add_column :urls, :meta_title, :string
    add_column :urls, :meta_description, :text
  end
end
