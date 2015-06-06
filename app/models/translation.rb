class Translation < ActiveRecord::Base	

	validates :name, :inprogram, presence: true

	has_one :lexem 
	has_one :number 
	has_one :translationsting
	has_one :variable
	has_one :error
	has_one :syntex

end
