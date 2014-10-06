class Object
  
  def keys_to_sym!
    self.keys.each do |key|
      self[ key ].keys_to_sym! if self[ key ].is_a?( Hash ) || self[ key ].is_a?( Array ) 
      self[ ( key.to_sym rescue key ) ] = self.delete( key )
    end
    self
  end
    
end