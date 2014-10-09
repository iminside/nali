module Nali
  
  def self.path
    @gem_path ||= File.expand_path '..', File.dirname( __FILE__ )
  end
  
end