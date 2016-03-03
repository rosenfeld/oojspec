# oojspec - Object-oriented client-side testing

`oojspec` is a test runner built on top of [Buster.js](http://busterjs.org/), focused on
integration tests. It is available both as a Rails engine and as an NPM package. Even though
I'd recommend to use the NPM package with the Karma runner for non-Rails projects (or even for
Rails projects it may be a better option) the Rails engine can also be used by non-Rails projects
- more on that in a later topic.

It uses the same assertions and reporter and you can choose between expectations
and assertions style on your examples or even mix them up.

This is heavily inspired by another beloved tool called [RSpec](https://www.relishapp.com/rspec/),
and also takes some inspiration from Jasmine and Buster.

I really prefer writing expectations instead of assertions because I think it reads better. But
on the other hand I find expectations an overkill for things like:

```javascript
expect(seats.length).toBeTruthy()
```

I'd rather prefer to write:

```javascript
assert(seats.length)
```

For a more in-depth introduction, please check-out [this article](http://rosenfeld.herokuapp.com/en/articles/programming/2012-07-20-client-side-code-testing-with-oojspec).

# Examples

[Here is how it looks like](http://oojspec.herokuapp.com/)
(yeah, I know it is failing - it is on purpose so that you can see
how the report looks like).

Feel free to explore it in jsfiddle:

- [JavaScript example with test runner](http://jsfiddle.net/rosenfeld/FWtaZ/)
- [JavaScript example without test runner](http://jsfiddle.net/rosenfeld/W3BCJ/)
- [CoffeeScript example with test runner](http://jsfiddle.net/rosenfeld/qJSyz/)
- [CoffeeScript example without test runner](http://jsfiddle.net/rosenfeld/37Qdn/)

Or some object-oriented approach:

- [JavaScript OO approach](http://jsfiddle.net/rosenfeld/mkw3v/)
- [CoffeeScript OO approach](http://jsfiddle.net/rosenfeld/ze8mU/)

And finally [a more complete suite](http://jsfiddle.net/rosenfeld/wgBJg/)
demonstrating lots of the features available. This was extracted from the test
application and is expected to fail. The result should be the same as the first
example of this section, hosted on Heroku.

# Is it production ready?

It should be, but its API is certainly going to change a lot before it becomes stable.

So I wouldn't advise you to write tons of tests with `oojspec` because you might have to rewrite
them in the future when the API changes.

On the other side, I use it myself in my own projects and the API hasn't change for a few years
now.

It still misses the feature of running an specific test, but since the tests could rely on
previous tests, I need to think in some way to specify the interdependencies of the tests before
I could implement some test filter to run a single test and its dependencies. It's not easy to
find time to work on this though with two little girls at home.

# Where are its tests?

I'm still not sure on how to properly test it. For the time being, I'm writing some examples
in a [separate project](http://github.com/rosenfeld/oojspec-test).

# Why not just using Buster.js (or Jasmine.js)?

Jasmine.js doesn't support beforeAll/afterAll and that was the main motivation I started to develop
another test runner. But let's be honest, I didn't want to maintain all expectations/assertions by
myself. Also I didn't want to worry about the reporter. I just wanted to focus on the runner itself.

Mocha/Chai seemed a great alternative but I had to support older Internet Explorer in my
application while the syntax of Chai required a feature not supported by those browsers.

Then I've heard about this excellent testing tool called Buster.js. It supported beforeAll/afterAll
just like Mocha but it didn't give any guarantees about the order of execution of the tests and
I needed that guarantee for some integration tests.

But on the other side it is pretty modular and I would be able to take advantage of their
assertions and expectations syntax as well as its reporter (although I had to change it a bit so
that it fit my taste).

As Buster.js allowed me to focus on the runner itself I decided to begin this new project.

Also I took the chance to do things the correct way in my opinion. I don't like the fact that most
test runners (all of them?) will publish `describe`, `it`, `waitsFor` etc. independently from the
context.

In contrast `oojspec` will only export `describe`. The other allowed features will be available
depending on the context. Inside a description `example`, `specify`, `it`, `xit`, `pending` and
`describe` will be available. Inside an example `expect`, `assert`, `waitsFor` and `runs` will be
available.

# Custom events

Oojspec supports custom events as well since v0.1.0 in case you want to notify and
listen to custom events:

```coffeescript
oojspec.on 'my-suite-start', (opts)-> console.log 'suite has started', opts
oojspec.on 'my-suite-end', -> console.log 'suite has ended'
oojspec.notify 'my-suite-start', option1: 1, option2: 'any'
oojspec.describe 'some description', -> @example 'it passes', -> @console.log 'suite is running'
oojspec.notify 'my-suite-end'

# this will log 'suite has started', {option1: 1, option2: 'any'},
    'suite is running' and finally 'suite has ended'
```

# CoffeeScript?! Really?!

JavaScript?! Really?!

This is me who is writing this runner and I dislike JavaScript, so please keep your preferences
for you. I won't change to pure JavaScript. Period.

But this project won't force your application to depend on CoffeeScript either. It uses webpack
to generate the final JS which is packaged both in the Rails engine gem and in the NPM package.

# Can I test my JavaScript code with oojspec despite it being written in CS?

Of course. Why are you asking me that?

On the other hand I'd advise you to write your examples in CoffeeScript for brevity.

JavaScript example:

```javascript
oojspec.describe('Some description', function(){
  this.example('Some example', function(){
    this.assert(true)
  })
});
```

CoffeeScript version:

```coffeescript
oojspec.describe 'Some description', ->
  @example 'Some example', -> @assert true
```

Alternatively, you can use some shortcut to `this` if you're using JavaScript:

```javascript
oojspec.describe('Some description', function(s){
  s.example('Some example', function(s){
    s.assert(true)
  })
});
```

But I'm not sure if this API will remain supported in the future although I don't currently have
any plans to change it.

# Usage with Rails

`oojspec` is also a Rails engine built on top of
[rails-sandbox-assets](https://github.com/rosenfeld/rails-sandbox-assets).

It takes advantage of the Rails asset pipeline to run your specs. To launch the runner, after
including `oojspec` to your Gemfile, run `rake sandbox_assets:serve`.

It will load all your specs inside `(spec|test)/javascripts/oojspec/` named `*_spec.js[.coffee]`
or `*_test.js[.coffee]`. Then run the examples by accessing http://localhost:5000/oojspec.

If you want to put your specs directly on `spec/javascripts`, add this to your application.rb:

```ruby
config.sandbox_assets.template = 'oojspec/runner'
config.sandbox_assets.iframe_template = 'oojspec/iframe'
```

Then you'll be able to run the specs by directly accessing http://localhost:5000.

By default this gem will expose `oojspec.describe` to the `window` object so that you can write it
directly from the top-level, but you can disable this exposition if you prefer:

```ruby
config.sandbox_assets.options[:skip_oojspec_expose] = true
```

# What about non-Rails applications?

There are a few ways you can use oojspec with non-Rails applications.

## Integrate the NPM package with the Karma runner

This is what I recommend most. There's some in-progress work to integrate oojspec and Karma
and I'll describe the details here soon.

## Using the Rails engine

If you want to take advantage of the Rails asset pipeline,
[here](https://github.com/rosenfeld/jasmine_assets_enabler/tree/oojs)
is an example on how to integrate the `rails-sandbox-assets` gem (and consequently this one) to
your non-Rails application.

It is target to the `oojs` gem that is currently built on top of `rails_sandbox_jasmine` but this
is going to change and `oojs` will be built on top of `oojspec` in the future. But you can currently
just add both gems right now and ignore the Jasmine runner while I don't change `oojs`.

## Do it yourself approach

You can also clone this project and run webpack to compile the source. Then you can write your
own custom runner HTML. Just take the template provided by this gem as an example on how to
write it.

Alternatively you can take a look at the jsfiddle demos from the Examples section.

# Plans for the future

There are so many but I'm not sure how long it will take to implement all of the intended
features in my spare time.

I'd like to support `given-and-when-and-then-and` style specs at some point.

But I wanted to have some initial working version published soon before someone register an
`oojspec` gem or NPM package before me! :)

# Contributing

I'd love to hear your opinions on the API and design of `oojspec` and of course contributions
will be very welcome if they're aligned with this project goals.

Enjoy! :)
