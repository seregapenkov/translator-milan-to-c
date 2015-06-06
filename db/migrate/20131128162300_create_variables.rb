class CreateVariables < ActiveRecord::Migration
  def change
    create_table :variables do |t|
      t.integer   :translation_id
	  t.string    :variable
	  t.integer   :first_index
	  t.integer   :second_index
      t.timestamps
    end
  end
end
