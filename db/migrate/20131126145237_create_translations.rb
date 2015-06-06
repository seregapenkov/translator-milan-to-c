class CreateTranslations < ActiveRecord::Migration
  def change
    create_table :translations do |t|
      t.string   :name
      t.string   :inprogram
      t.string	 :outprogram
      t.timestamps
    end
  end
end
