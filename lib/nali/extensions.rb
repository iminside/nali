class Object
  
  def keys_to_sym!
    self.keys.each do |key|
      self[ key ].keys_to_sym! if self[ key ].is_a?( Hash )
      self[ ( key.to_sym rescue key ) ] = self.delete( key )
    end
    self
  end
    
end

class String
   
  def underscore!
    gsub!( /(.)([A-Z])/, '\1_\2' )
    downcase!
  end

  def underscore
    dup.tap { |s| s.underscore! }
  end
  
  def camelize
    self.split( '_' ).collect( &:capitalize ).join
  end
  
end