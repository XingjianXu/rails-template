# Author: Xingjian
# Rails 5.0+

gem 'slim-rails', github: 'slim-template/slim-rails'
gem 'settingslogic'
gem 'kaminari'
gem 'gon'
gem 'draper', github: 'drapergem/draper'
gem 'semantic-ui-sass', github: 'doabit/semantic-ui-sass'
gem 'bourbon'
gem 'rails-ujs'
gem 'js-routes'
gem 'high_voltage', github: 'thoughtbot/high_voltage'
gem 'mina', require: false
gem 'mina-puma', require: false
gem 'mina-logs', require: false


gem_group :development do
	gem 'pry-rails'
end

require 'securerandom'
secret = SecureRandom.hex(64)
db_host = ask 'Database host:'
db_user = ask 'Database username:'
db_passwd = ask 'Database password:'

file 'config/config.yml', <<-RUBY
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
RUBY

run 'cp config/config.yml config/config.yml.example'
append_to_file '.gitignore', "config/config.yml\n"

application <<-RUBY
  require File.expand_path('../../app/models/config.rb', __FILE__)
  config.action_controller.permit_all_parameters = true
  config.relative_url_root = Config.relative_root
	config.sass.preferred_syntax = :sass
RUBY

file 'app/models/config.rb', <<-RUBY
class Config < Settingslogic
  source "\#{Rails.root}/config/config.yml"
  namespace Rails.env
end
RUBY

file 'app/helpers/body_class_helper.rb', <<-RUBY
module BodyClassHelper
  def body_class(options = {})
    extra_body_classes_symbol = options[:extra_body_classes_symbol] || :extra_body_classes
    qualified_controller_name = controller.controller_path.gsub('/','-')
    basic_body_class = "\#{qualified_controller_name} \#{qualified_controller_name}-\#{controller.action_name}"

    if content_for?(extra_body_classes_symbol)
      [basic_body_class, content_for(extra_body_classes_symbol)].join(' ')
    else
      basic_body_class
    end
  end
end
RUBY

file 'app/helpers/page_title_helper.rb', <<-RUBY
module PageTitleHelper
  def page_title(options = {})
    app_name = options[:app_name] || Rails.application.class.to_s.split('::').first
    page_title_symbol = options[:page_title_symbol] || :page_title
    separator = options[:separator] || ' | '

    if content_for?(page_title_symbol)
      [app_name, content_for(page_title_symbol)].join(separator)
    else
      app_name
    end
  end
end
RUBY

file 'app/helpers/misc_helper.rb', <<-RUBY
module MiscHelper
  def active?(options)
    if options.is_a? String
      request.path.starts_with? options
    else
      r = false
      if options[:controller]
        r = params[:controller] == options[:controller]
      end
      if options[:action]
        r = r && params[:action] == options[:action]
      end
      r
    end
  end

  def active_class(options)
    active?(options) ? 'active' : ''
  end

  def empty_safe(e, empty_msg, &block)
    if e.present?
      capture(&block)
    else
      content_tag :div, content_tag(:p, empty_msg), class: 'empty-placeholder'
    end
  end
end
RUBY

gsub_file 'config/secrets.yml', /production:\n\s\ssecret_key_base:.+/, <<-RUBY
production:
  secret_key_base: <%= Config.secret %>
RUBY

gsub_file 'config/environments/production.rb', /config\.log_level = :debug/, 'config.log_level = :error'

inject_into_file 'config/database.yml', after: "default: &default\n" do <<-'RUBY'
  username: <%=Config.db.username %>
  password: <%=Config.db.password %>
  host: <%=Config.db.host %>
RUBY
end

initializer 'jsroutes.rb', <<-RUBY
JsRoutes.setup do |config|
  config.compact = true
end
RUBY

# Gem bullet
gem_group :development do
	gem 'bullet'
end

environment <<-RUBY, env: 'development'
config.after_initialize do
  Bullet.enable = true
  Bullet.rails_logger = true
end
RUBY

route "root 'home#index'"

remove_file 'app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.slim', <<-SLIM
doctype 5
html lang='en'
  head
    meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no'
    title = page_title 
    = csrf_meta_tags
    = stylesheet_link_tag 'application', media: 'all'
    = javascript_include_tag 'jquery/dist/jquery.js'
    = javascript_include_tag 'application'

  body class=body_class
    #container
    = yield
SLIM

after_bundle do
	run 'bin/yarn add jquery'
end

append_file 'config/initializers/assets.rb', 'Rails.application.config.assets.precompile += %w( jquery/dist/jquery.js )'

