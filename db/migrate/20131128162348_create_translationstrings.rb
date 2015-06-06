class CreateTranslationstrings < ActiveRecord::Migration
  def change
    create_table :translationstrings do |t|
      t.integer   :translation_id
	  t.string    :translationstring
	  t.integer   :first_index
	  t.integer   :second_index
      t.timestamps
    end
  end
end
