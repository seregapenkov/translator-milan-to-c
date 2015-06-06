class Reservedkeyword < ActiveRecord::Base

	validates :keywords, presence: true

end
