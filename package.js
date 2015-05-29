Package.describe({
  name: 'nisargshah100:meteororm',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: 'ORM for Meteor - ActiveRecord inspired',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.use('coffeescript');
  api.use('underscore');
  api.versionsFrom('1.1.0.2');

  api.addFiles('src/init.coffee');
  api.addFiles('lib/deep.coffee');
  api.addFiles('lib/deepExtend.js');
  api.addFiles('src/module.coffee');
  api.addFiles('src/query.coffee');
  api.addFiles('src/hooks.coffee');
  api.addFiles('src/validation.coffee')
  api.addFiles('src/meteororm.coffee');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('autopublish');
  api.use('coffeescript');
  api.use('nisargshah100:meteororm');

  api.addFiles('test/meteororm-test.coffee');
});
