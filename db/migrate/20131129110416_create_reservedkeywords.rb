class CreateReservedkeywords < ActiveRecord::Migration
  def change
    create_table :reservedkeywords do |t|
      t.text     :keywords
      t.timestamps
    end
  end
end
