class Admin < User
	class_table_inheritance

	attr_accessible :permission
end