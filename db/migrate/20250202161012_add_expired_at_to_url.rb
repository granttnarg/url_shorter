class AddExpiredAtToUrl < ActiveRecord::Migration[7.1]
  def change
    add_column :urls, :expired_at, :datetime
  end
end
