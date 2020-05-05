class MakeParticipantAttributesHash < ActiveRecord::Migration[6.0]
  def up
    change_table(:participants) do |t|
      t.json :extras, null: false, default: {}
    end
    remove_belongs_to :participant_attributes, :participant
    drop_table :participant_attributes
  end

  def down
    create_table :participant_attributes, id: :uuid do |t|
      t.string :key
      t.string :value
      t.belongs_to :participant, type: :uuid

      t.timestamps
    end

    change_table(:participants) do |t|
      t.remove :extras
    end
  end
end
