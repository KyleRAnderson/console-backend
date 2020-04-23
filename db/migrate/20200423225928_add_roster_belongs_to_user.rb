class AddRosterBelongsToUser < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :rosters, :user
  end
end
