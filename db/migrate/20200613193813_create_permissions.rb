class CreatePermissions < ActiveRecord::Migration[6.0]
  def change
    create_table :permissions, id: :uuid do |t|
      # Owner by default, for creating rosters easily.
      t.integer :level, null: false, default: 0
      t.belongs_to :user, null: false, foreign_key: true, type: :uuid, index: false
      t.belongs_to :roster, null: false, foreign_key: true, type: :uuid, index: false
      t.index %i[user_id roster_id], unique: true

      t.timestamps
    end
    remove_column :rosters, :user_id
  end
end
