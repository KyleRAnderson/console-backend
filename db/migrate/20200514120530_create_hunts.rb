class CreateHunts < ActiveRecord::Migration[6.0]
  def change
    create_table :hunts, id: :uuid do |t|
      t.string :name
      t.belongs_to :roster, type: :uuid

      t.timestamps
    end
  end
end
