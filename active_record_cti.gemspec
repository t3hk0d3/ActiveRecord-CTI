# -*- encoding: utf-8 -*-
require File.expand_path('../lib/active_record_cti/version', __FILE__)

Gem::Specification.new do |gem|
	gem.authors = ["t3hk0d3"]
	gem.email = ["clouster@yandex.ru"]
	gem.description = %q{ActiveRecord plugin implementing Class Table Inheritance pattern}
	gem.summary = %q{ActiveRecord plugin implementing Class Table Inheritance pattern}
	gem.homepage = ""

	gem.files = `git ls-files`.split("\n")
	gem.executables = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
	gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
	gem.name = "active_record_cti"
	gem.require_paths = ["lib"]
	gem.version = ActiveRecordCti::VERSION

	gem.add_development_dependency "rake"
	gem.add_development_dependency "bundler"
	gem.add_development_dependency "sqlite3"
	gem.add_development_dependency "rspec-rails"
	gem.add_development_dependency "rails"
	gem.add_development_dependency "database_cleaner"

	gem.add_dependency "activerecord"
end
