class CreateSyntexes < ActiveRecord::Migration
  def change
    create_table  :syntexes do |t|
      t.integer   :translation_id
	  t.string    :rule
      t.timestamps
    end
  end
end
