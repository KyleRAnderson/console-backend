class RemoveMatchOpen < ActiveRecord::Migration[6.0]
  def change
    remove_column :matches, :open, :boolean
  end
end
