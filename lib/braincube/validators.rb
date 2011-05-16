module Braincube
  module Validators
    
    class TreeValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        if record.id && (record.id==record[attribute])
          record.errors[attribute] << (options[:message] || "cannot refer to self") 
        end
      end
    end
    
    class UrlValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return unless record[attribute]
        unless record[attribute].match Braincube::Config::UrlRegexp
          record.errors[attribute] << (options[:message] || "contains invalid characters") 
        end
      end
    end
    
    class EmptyValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if record[attribute].blank?
        record.errors[attribute] << (options[:message] || "should be left empty") 
      end
    end
    
    class EmailValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return unless record[attribute]
        unless record[attribute].match Braincube::Config::EmailRegexp
          record.errors[attribute] << (options[:message] || "should be a valid email address") 
        end
      end
    end
    
  end
end

ActiveRecord::Base.send(:include, Braincube::Validators)
