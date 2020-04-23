class AddParticipantRosterRelations < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :participants, :roster
  end
end
