var htmlparser = require('htmlparser2')
var parser = new htmlparser.Parser({
  onopentag: function (name, attribs) {
  },
  ontext: function (text) {
  },
  onclosetag: function (tagname) {
    
  }
})
process.stdin.pipe(parser)
