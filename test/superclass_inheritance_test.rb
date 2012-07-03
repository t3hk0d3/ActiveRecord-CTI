require 'active_record'
require 'test/unit'
require 'logger'

require '../lib/active_record_cti/class_inheritance.rb'


class SuperclassInheritanceTest < Test::Unit::TestCase

	# Called before every test method runs. Can be used
	# to set up fixture information.
	def setup
		ActiveRecord::Base.establish_connection({:adapter => "sqlite3", :database => "test.sqlite"})
		ActiveRecord::Base.logger = Logger.new(STDERR)

		load "schema.rb" unless File.exist?("test.sqlite")

		require_relative "models/person"
		require_relative "models/user"
		require_relative "models/admin"
	end

	# Called after every test method runs. Can be used to tear
	# down fixture information.

	def teardown
		ActiveRecord::Base.clear_all_connections!
		#File.delete "test.sqlite"
	end

	def test_crud
		ActiveRecord::Base.logger.debug "Testing create"
		# Test insert
		user = Admin.create(:first_name => "John", :sur_name => "White", :last_name => "Smith", :login => "john_smith", :email => "j.smith@nsa.gov", :permission => "foobar")

		ActiveRecord::Base.logger.debug "Testing created"
		assert_nothing_raised ActiveRecord::RecordNotFound do
			user = Admin.find(user.id)
		end

		# Test update
		ActiveRecord::Base.logger.debug "Testing update"

		user.first_name = "Jack"
		user.login = "jack_smith"
		user.permission = "barfoo"

		user.save

		ActiveRecord::Base.logger.debug "Testing updated"

		testUser = Admin.find(user.id)

		assert_equal "Jack", testUser.first_name
		assert_equal "jack_smith", testUser.login
		assert_equal "barfoo", testUser.permission

		# Test destroy
		ActiveRecord::Base.logger.debug "Testing destroy"
		user.destroy

		ActiveRecord::Base.logger.debug "Testing destroyed"
		assert_raise ActiveRecord::RecordNotFound do
			user = Admin.find(user.id)
		end


	end

	def test_relations


	end

	def test_polymorphism
		ActiveRecord::Base.logger.debug "Testing polymorphism"

		admin = Admin.create(:first_name => "John", :sur_name => "White", :last_name => "Smith", :login => "john_smith", :email => "j.smith@nsa.gov", :permission => "foobar")

		user = User.find(admin.id)
		person = Person.find(user.id)


		assert_equal(admin, person)
		assert_equal(admin, user)
	end

end