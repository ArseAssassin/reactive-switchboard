require('./globals')
const reactDom = require('react-dom'),
      App = require('./components/App');

reactDom.render(<App />, document.getElementById('host'))

