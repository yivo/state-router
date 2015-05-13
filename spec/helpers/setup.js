var jsdom;

jsdom = require('jsdom').jsdom;

global.document = jsdom('<html><head><script></script></head><body></body></html>', null, {
  FetchExternalResources: ['script'],
  ProcessExternalResources: ['script'],
  MutationEvents: '2.0',
  QuerySelector: false
});

global.window = document.createWindow();

global.navigator = global.window.navigator;

global.window.Node.prototype.contains = function(node) {
  return this.compareDocumentPosition(node) & 16;
};

global.$ = require('jquery');

global._ = require('lodash');

global.XRegExp = require('xregexp').XRegExp;

require('yess');

require('coffee-concerns');

global.StrictParameters = require('strict-parameters');

global.PublisherSubscriber = require('pub-sub');

global.StateRouter = require('../../build/state-router.js');
