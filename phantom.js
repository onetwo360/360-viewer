var page = require('webpage').create();
var url = 'http://localhost:4444/test.html';
page.open(url, function (status) {
  console.log(status);
});
