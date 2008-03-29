# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_blog_session',
    :secret      => '39af6fe0b86a92d359e28d6728d36c4ea3922a5e112cadb33bd886f8ecad4a5599a0ff3b4146b490d602021e0d3b6962c5313255115d30022b916aefbfbab1d8'
  }
  config.action_mailer.delivery_method = :sendmail
  #config.active_record.allow_concurrency = true
  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
end

module ActiveRecord
  class Errors
    @@default_error_messages = {
      :inclusion => "is not included in the list",
      :exclusion => "is reserved",
      :invalid => "is invalid",
      :confirmation => "doesn't match confirmation",
      :accepted  => "must be accepted",
      :empty => "не может быть пустым",
      :blank => "не может быть пустым",
      :too_long => "слишком длинное (максимум %d символа)",
      :too_short => "слишком короткое (минимум %d символа)",
      :wrong_length => "is the wrong length (should be %d characters)",
      :taken => "has already been taken",
      :not_a_number => "is not a number",
      :greater_than => "must be greater than %d",
      :greater_than_or_equal_to => "must be greater than or equal to %d",
      :equal_to => "must be equal to %d",
      :less_than => "must be less than %d",
      :less_than_or_equal_to => "must be less than or equal to %d",
      :odd => "must be odd",
      :even => "must be even"
    }
    def full_messages
      full_messages = []

      @errors.each_key do |attr|
        @errors[attr].each do |msg|
          next if msg.nil?

          if attr == "base"
            full_messages << msg
          else
            full_messages << "Поле \"" + @base.class.human_attribute_name(attr) + "\" " + msg
          end
        end
      end
      full_messages
    end
  end

end

module ActionView
  module Helpers
    module ActiveRecordHelper
      def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys
        if object = options.delete(:object)
          objects = [object].flatten
        else
          objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        end
        count   = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'errorExplanation'
            end
          end
          options[:object_name] ||= params.first
          options[:header_message] = "#{count} #{count.items("ошибка", "ошибки", "ошибок")} #{count.items("была", "было", "было")} #{count.items("обнаружена", "обнаружено", "обнаружено")} при сохранении" unless options.include?(:header_message)
          options[:message] ||= 'Ошибки в следующих полях:' unless options.include?(:message)
          error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }

          contents = ''
          contents << content_tag(options[:header_tag] || :h2, options[:header_message]) unless options[:header_message].blank?
          contents << content_tag(:p, options[:message]) unless options[:message].blank?
          contents << content_tag(:ul, error_messages)

          content_tag(:div, contents, html)
        else
          ''
        end
      end
    end
  end
end