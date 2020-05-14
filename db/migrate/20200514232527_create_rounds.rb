class CreateRounds < ActiveRecord::Migration[6.0]
  def change
    create_table :rounds, id: :uuid do |t|
      t.belongs_to :hunt, null: false, foreign_key: true, type: :uuid
      t.integer :number, null: false

      t.timestamps
    end
  end
end
