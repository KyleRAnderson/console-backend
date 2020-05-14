class CreateParticipantAttributes < ActiveRecord::Migration[6.0]
  def change
    create_table :participant_attributes, id: :uuid do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
    add_belongs_to :participant_attributes, :participant, type: :uuid, foreign_key: true
  end
end
