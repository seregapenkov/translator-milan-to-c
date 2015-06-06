class CreateNumbers < ActiveRecord::Migration
  def change
    create_table :numbers do |t|
      t.integer   :translation_id
	  t.string    :number
	  t.integer   :first_index
	  t.integer   :second_index
      t.timestamps
    end
  end
end
