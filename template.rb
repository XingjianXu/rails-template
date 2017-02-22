# Author: Xingjian
# Rails 5.0+
gem 'settingslogic'

gem 'kaminari'

gem 'gon'
gem 'font-awesome-sass'
gem 'bootstrap-sass'
gem 'bourbon'
gem 'jquery-rails'
gem 'js-routes'
gem 'mina'
gem 'mina-puma'

gem_group :development do
	gem 'pry-rails'
end

require 'securerandom'
secret = SecureRandom.hex(64)
db_host = ask 'Database host:'
db_user = ask 'Database username:'
db_passwd = ask 'Database password:'

file 'config/config.yml', <<-CODE
defaults: &defaults
  relative_root: '/'
  secret: '#{secret}'
  db:
    host: #{db_host}
    username: #{db_user}
    password: #{db_passwd}

development:
  <<: *defaults

test:
  <<: *defaults

production:
  <<: *defaults
CODE

application <<-CODE
  require File.expand_path('../../app/models/config.rb', __FILE__)
  config.action_controller.permit_all_parameters = true
  config.relative_url_root = Config.relative_root
CODE

gsub_file 'config/secrets.yml', /production:\n\s\ssecret_key_base:.+/, <<-CODE
production:
  secret_key_base: <%= Config.secret %>
CODE

inject_into_file 'config/database.yml', after: "default: &default\n" do <<-'CODE'
  username: <%=Config.db.username %>
  password: <%=Config.db.password %>
  host: <%=Config.db.host %>
CODE
end

initializer 'jsroutes.rb', <<-CODE
JsRoutes.setup do |config|
  config.compact = true
end
CODE

route "root 'home#index'"
