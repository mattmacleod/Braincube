module Braincube #:nodoc:
  module ModelExtensions #:nodoc:

    module Properties #:nodoc:

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods

          def braincube_has_properties( *columns )

            # Default property columns for this model
            cattr_accessor :default_property_columns
						attr_accessible *columns
						
            self.default_property_columns = columns.blank? ? [:properties] : columns

            self.default_property_columns.each do |column|
              serialize (column)
              define_method "#{column}=" do |props|
                self[column] = (self[column] || {}).merge(props || {})
              end

              define_method "#{column}" do
								if self[column] && !self[column].blank?
									return self[column].symbolize_keys.merge(self[column].stringify_keys)
								else
	                return {}
								end
              end
            end
            include Braincube::ModelExtensions::Properties::InstanceMethods

          end

        end


        module InstanceMethods



        end

    end
  end
end

ActiveRecord::Base.send(:include, Braincube::ModelExtensions::Properties)
