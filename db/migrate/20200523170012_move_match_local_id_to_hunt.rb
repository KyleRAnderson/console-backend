class MoveMatchLocalIdToHunt < ActiveRecord::Migration[6.0]
  def change
    remove_column :rounds, :current_match_id
    add_column :hunts, :current_match_id, :bigint, null: false, default: 0
  end
end
