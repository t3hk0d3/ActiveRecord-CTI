class Person < ActiveRecord::Base

	attr_accessible :first_name, :last_name, :sur_name

	validates :first_name, :presence => true
	validates :last_name, :presence => true
	validates :sur_name, :presence => true

end