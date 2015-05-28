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

  api.addFiles('src/_init.coffee');
  api.addFiles('src/_deep.coffee');
  api.addFiles('src/_module.coffee');
  api.addFiles('src/_mongoobject.js');
  api.addFiles('src/_deepExtend.js');
  api.addFiles('src/query.coffee');
  api.addFiles('src/meteororm.coffee');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('insecure');
  api.use('autopublish');
  api.use('coffeescript');
  api.use('nisargshah100:meteororm');

  api.addFiles('test/meteororm-test.coffee');
});
