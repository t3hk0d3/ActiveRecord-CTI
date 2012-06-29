require_relative "person"

class User < Person
	class_table_inheritance

	attr_accessible :login, :email
	validates :login, :presence => true
	validates :email, :presence => true
end