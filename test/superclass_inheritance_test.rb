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

	def test_select
		users = Admin.where(:first_name => "john_smith", "people.last_name" => "Freeman").where(["last_name = ?", "Freeman"]).order("login DESC");

		p users
	end

	def test_insert
		# Test insert
		user = Admin.create(:first_name => "John", :sur_name => "White", :last_name => "Smith", :login => "john_smith", :email => "j.smith@nsa.gov", :permission => "foobar")

		# Test update

		user.first_name = "Jack"
		user.login = "jack_smith"
		user.permission = "barfoo"

		user.save

		# Test select


		# Test destroy
		user.destroy

	end

	def test_update

	end

	def test_delete

	end

	def test_associations

	end

	def test_inheritance

	end
end