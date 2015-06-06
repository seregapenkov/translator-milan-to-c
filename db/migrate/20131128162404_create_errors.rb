class CreateErrors < ActiveRecord::Migration
  def change
    create_table :errors do |t|
      t.integer   :translation_id
	  t.string    :discription
	  t.integer   :string_number
      t.timestamps
    end
  end
end
