module Sprockets
  module Helpers
    
    def templates_tags
      result = ''
      Dir[ File.join( './app/templates/*/*' ) ].each do |path|
        arr      = path.split( '/' ).reverse
        id       = arr[1] + '_' + arr[0].split( '.' )[0]
        asset    = environment[ path ]
        template = asset.body.force_encoding( 'UTF-8' ).strip.gsub( "\n", "\n      " )
        result  += %Q(\n    <script type=\"text/template\" id=\"#{ id }\">\n      #{ template }\n    </script>)
        depend_on asset.pathname
      end
      result
    end
  
  end
end