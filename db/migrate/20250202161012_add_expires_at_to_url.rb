class AddExpiresAtToUrl < ActiveRecord::Migration[7.1]
  def change
    add_column :urls, :expires_at, :datetime
  end
end
