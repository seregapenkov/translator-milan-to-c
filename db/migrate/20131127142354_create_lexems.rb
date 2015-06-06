class CreateLexems < ActiveRecord::Migration
  def change
    create_table :lexems do |t|
    t.integer   :translation_id
	  t.string    :lexema
	  t.integer   :first_index
	  t.integer   :second_index
	  t.integer   :index_number
      t.timestamps
    end
  end
end
