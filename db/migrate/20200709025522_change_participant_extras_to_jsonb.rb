class ChangeParticipantExtrasToJsonb < ActiveRecord::Migration[6.0]
  def change
    # Not much reason for doing this, since not much has changed, but there are supposedly some
    # speed benefits for querying and reading:
    # - https://www.compose.com/articles/faster-operations-with-the-jsonb-data-type-in-postgresql/
    # - https://www.netguru.com/codestories/postgres-arrays-vs-json-datatypes-in-rails-5#:~:text=to%20nest%20data.-,JSON,less%20storage%20compared%20to%20jsonb.
    change_column :participants, :extras, :jsonb, null: false, default: {}
  end
end
