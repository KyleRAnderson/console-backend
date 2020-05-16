class AddMatchesLicenses < ActiveRecord::Migration[6.0]
  def change
    create_table :matches, id: :uuid do |t|
      t.boolean :open, default: true, null: false
      t.belongs_to :round, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    create_table :licenses, id: :uuid do |t|
      t.boolean :eliminated, default: false, null: false
      t.belongs_to :hunt, null: false, foreign_key: true, type: :uuid
      t.belongs_to :participant, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    create_join_table(:licenses, :matches) do |t|
      t.belongs_to :license, null: false, foreign_key: true, type: :uuid
      t.belongs_to :match, null: false, foreign_key: true, type: :uuid
    end
  end
end
