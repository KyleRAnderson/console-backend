class CreateParticipants < ActiveRecord::Migration[6.0]
  def change
    create_table :participants, id: :uuid do |t|
      t.string :first
      t.string :last

      t.timestamps
    end
  end
end
