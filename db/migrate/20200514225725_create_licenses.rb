class CreateLicenses < ActiveRecord::Migration[6.0]
  def change
    create_table :licenses, id: :uuid do |t|
      t.boolean :eliminated, default: false, null: false
      t.belongs_to :hunt, null: false, foreign_key: true, type: :uuid
      t.belongs_to :participant, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
