class CreateReservedsymbols < ActiveRecord::Migration
  def change
    create_table :reservedsymbols do |t|
      t.text	 :symbols
      t.timestamps
    end
  end
end
