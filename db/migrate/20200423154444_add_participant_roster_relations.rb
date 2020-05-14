class AddParticipantRosterRelations < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :participants, :roster, type: :uuid, foreign_key: true
  end
end
