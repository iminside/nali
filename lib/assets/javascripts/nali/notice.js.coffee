Nali.Model.extend Notice:        
  initialize:         -> @::::Notice = @
  info:    ( params ) -> @build( params ).show 'info'
  warning: ( params ) -> @build( params ).show 'warning'
  error:   ( params ) -> @build( params ).show 'error'

Nali.View.extend NoticeInfo: 
  onShow: -> @hide 3000

Nali.View.extend NoticeWarning: 
  onShow: -> @hide 3000
    
Nali.View.extend NoticeError:   
  onShow: -> @hide 3000