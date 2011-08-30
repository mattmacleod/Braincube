
class AssetFolder < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  # Relationships
  belongs_to :parent, :class_name=>"AssetFolder"
  has_many :children, :class_name=>"AssetFolder", :foreign_key=>:parent_id,
           :dependent => :destroy, :order => "name ASC"
  has_many :assets
  
  # Validations
  validates :name, :presence => true
  validates_uniqueness_of :name, :scope => :parent_id, :case_sensitive => false
  validates_associated :parent
  validates :parent_id, :tree => true
  
  after_save :clear_node_cache
  after_destroy :clear_node_cache
    
  # Class methods
  ############################################################################
  
  def self.root
    return nodes.select{|n| n && !n.parent_id }.first
  end
  
  # Instance methods
  ############################################################################
  
  def ancestors
    return @ancestors ||= get_parent ? (get_parent.ancestors + [self]) : [self]
  end
  
  def to_param
    "#{id}-#{Braincube::Util.pretty_url(name)}"
  end
  
  def path
    ancestors.map{|a| a.to_param }
  end
  
  
  # Node caching to reduce queries
  ############################################################################
  
  cattr_accessor :nodes
  attr_accessor :child_ids
  def self.nodes
    return @nodes if ( @nodes && !Rails.env.test? )
    @nodes = []
    order(:id).each{|n| @nodes[n.id] = n }
    @nodes.each do |n| 
      if n && n.parent_id && @nodes[n.parent_id]
        @nodes[n.parent_id].child_ids ? (@nodes[n.parent_id].child_ids << n.id) : ( @nodes[n.parent_id].child_ids = [n.id])
      end
    end
    return @nodes
  end
  
  def self.with_id(id)
    return nodes[id.to_i] if nodes[id.to_i]
    raise ActiveRecord::RecordNotFound
  end
  
  def get_parent
    AssetFolder::nodes[self.parent_id] rescue nil
  end
  
  def get_children
    return self.child_ids.blank? ? [] : child_ids.map{|c| AssetFolder::nodes[c] }.sort_by(&:name)
  end
    
  def clear_node_cache
    self.class.clear_node_cache!
    self.child_ids = nil
  end
  
	def self.clear_node_cache!
		@nodes = nil
	end

end