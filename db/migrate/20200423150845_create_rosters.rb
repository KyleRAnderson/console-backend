class CreateRosters < ActiveRecord::Migration[6.0]
  def change
    create_table :rosters, id: :uuid do |t|
      t.string :name
      t.text :participant_properties

      t.timestamps
    end
  end
end
