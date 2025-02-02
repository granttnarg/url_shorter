class CreateUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :urls do |t|
      t.string :slug, null: false
      t.string :original

      t.timestamps
    end

    add_index :urls, :slug, unique: true
  end
end
