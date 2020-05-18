class AddMatchIdCountToRound < ActiveRecord::Migration[6.0]
  def change
    add_column :rounds, :current_match_id, :bigint, null: false, default: 1
    add_column :matches, :local_id, :bigint, null: false
    add_index :matches, :local_id
  end
end
