var sax = require('sax')
var parser = sax.createStream()
parser.onopentag = function () {}
parser.onontext = function () {}
process.stdin.pipe(parser)
