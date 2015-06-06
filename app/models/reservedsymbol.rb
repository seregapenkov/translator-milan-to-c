class Reservedsymbol < ActiveRecord::Base

	validates :symbols, presence: true

end
