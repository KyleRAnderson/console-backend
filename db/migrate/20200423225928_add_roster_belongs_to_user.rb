class AddRosterBelongsToUser < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :rosters, :user, type: :uuid
  end
end
