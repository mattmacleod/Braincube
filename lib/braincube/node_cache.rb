class Braincube::NodeCache
	cattr_accessor :node_flush_timestamp
	@@node_flush_timestamp = Time::now.to_i
end