class NodeSweeper < ActionController::Caching::Sweeper

  observe AssetFolder, Page
 
  def after_create(item)
    flush_cache
  end
 
  def after_update(item)
    flush_cache
  end
 
  def after_destroy(item)
    flush_cache
  end
 
  private
  
  def flush_cache
    File.open("#{Rails.root}/tmp/flush_node_cache.txt", 'w') {|f| f.write( Time::now.to_i ) }
  end
  
end