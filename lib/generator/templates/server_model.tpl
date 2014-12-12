class <%= classname %> < ActiveRecord::Base

  include Nali::Model

  def access_level( client )
    :unknown
  end

end
