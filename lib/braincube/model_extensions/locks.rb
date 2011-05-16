module Braincube #:nodoc:
  module ModelExtensions #:nodoc:
    module Lock #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end
            
      module ClassMethods
        
        def braincube_has_lock
          has_one :lock, :as => :lockable, :dependent => :destroy
          include Braincube::ModelExtensions::Lock::InstanceMethods
        end
        
      end

      module InstanceMethods
        
        def locked?
          return false unless lock
          if lock.updated_at < (2.minutes.ago)
            lock.destroy and return false
          else
            return true
          end
        end
        
        def unlock!(user=nil)
          if !user || (user && lock && (lock.user==user))
            lock.destroy if lock
            return true
          else
            return false
          end
        end
        
        def lock!(user)
          return nil if locked?
          ::Lock::create!(:lockable => self, :user => user, :created_at => Time::now, :updated_at => Time::now)
        end
        
      end
      
    end
  end
end
 
ActiveRecord::Base.send(:include, Braincube::ModelExtensions::Lock)
