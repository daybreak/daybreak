# -*- encoding: utf-8 -*-
  
Gem::Specification.new do |s|
  s.name = %q{markaby}
  s.version = "0.0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tim Fletcher", "why_", "Daniel Insley"]
  s.date = %q{2009-04-28}
  s.description = %q{Markaby is a very short bit of code for writing HTML pages in pure Ruby.}
  s.email = %q{dinsley@gmail.com  }
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "Rakefile",
    "VERSION.yml",
    "lib/markaby.rb",
    "lib/markaby/builder.rb",
    "lib/markaby/cssproxy.rb",
    "lib/markaby/metaid.rb",
    "lib/markaby/rails/action_controller_helpers.rb",
    "lib/markaby/rails/template_handler.rb",
    "lib/markaby/tags.rb",
    "test/app_root/app/controllers/application_controller.rb",
    "test/app_root/app/controllers/markaby_controller.rb",
    "test/app_root/app/helpers/test_helper.rb",
    "test/app_root/app/views/markaby/_monkeys.mab",
    "test/app_root/app/views/markaby/broken.mab",
    "test/app_root/app/views/markaby/create.mab",
    "test/app_root/app/views/markaby/index.mab",
    "test/app_root/app/views/markaby/multiple_forms.mab",
    "test/app_root/config/boot.rb",
    "test/app_root/config/database.yml",
    "test/app_root/config/environment.rb",
    "test/app_root/config/environments/in_memory.rb",
    "test/app_root/config/environments/mysql.rb",
    "test/app_root/config/environments/postgresql.rb",
    "test/app_root/config/environments/sqlite.rb",
    "test/app_root/config/environments/sqlite3.rb",
    "test/app_root/config/routes.rb",
    "test/app_root/lib/console_with_fixtures.rb",
    "test/app_root/script/console",
    "test/markaby_controller_test.rb",
    "test/markaby_test.rb",
    "test/monkeys.html",
    "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/dinsley/markaby}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Markaby is a very short bit of code for writing HTML pages in pure Ruby.}
  s.test_files = [
    "test/app_root/app/controllers/application_controller.rb",
    "test/app_root/app/controllers/markaby_controller.rb",
    "test/app_root/app/helpers/test_helper.rb",
    "test/app_root/config/boot.rb",
    "test/app_root/config/environment.rb",
    "test/app_root/config/environments/in_memory.rb",
    "test/app_root/config/environments/mysql.rb",
    "test/app_root/config/environments/postgresql.rb",
    "test/app_root/config/environments/sqlite.rb",
    "test/app_root/config/environments/sqlite3.rb",
    "test/app_root/config/routes.rb",
    "test/app_root/lib/console_with_fixtures.rb",
    "test/markaby_controller_test.rb",
    "test/markaby_test.rb",
    "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
