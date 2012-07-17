# oojspec - Object-oriented client-side testing

`oojspec` is a test runner built on top of [Buster.js](http://busterjs.org/), focused on
integration tests. It is also a Rails engine, although you can use it in non-Rails
applications - more on that in a later topic.

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

On the other side, I'll be using it myself in my own projects, replacing my Jasmine specs.

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
assertions and expectations syntax as well as its reporter (although I'm still not happy with
the default html reporter and I'll probably have to write a new one in the future).

As Buster.js allowed me to focus on the runner itself I decided to begin this new project.

Also I took the chance to do things the correct way in my opinion. I don't like the fact that most
test runners (all of them?) will publish `describe`, `it`, `waitsFor` etc. independently from the
context.

In contrast `oojspec` will only export `describe`. The other allowed features will be available
depending on the context. Inside a description `example`, `specify`, `it`, `xit`, `pending` and
`describe` will be available. Inside an example `expect`, `assert`, `waitsFor` and `runs` will be
available .

# CoffeeScript?! Really?!

JavaScript?! Really?!

This is me who is writing this runner and I dislike JavaScript, so please keep your preferences
for you. I won't change to pure JavaScript. Period.

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
```

Then you'll be able to run the specs by directly accessing http://localhost:5000.

By default this gem will expose `oojspec.describe` to the `window` object so that you can write it
directly from the top-level, but you can disable this exposition if you prefer:

```ruby
config.sandbox_assets.options[:skipt_oojspec_expose] = true
```

# What about non-Rails applications?

There are two ways you can use oojspec with non-Rails applications.

If you want to take advantage of the Rails asset pipeline,
[here](https://github.com/rosenfeld/jasmine_assets_enabler/tree/oojs)
is an example on how to integrate the `rails-sandbox-assets` gem (and consequently this one) to
your non-Rails application.

It is target to the `oojs` gem that is currently built on top of `rails_sandbox_jasmine` but this
is going to change and `oojs` will be built on top of `oojspec` in the future. But you can currently
just add both gems right now and ignore the Jasmine runner while I don't change `oojs`.

The other approach is to compile the source (possibly in the
[Try CoffeeScript page](http://coffeescript.org/)) and write your own custom runner HTML. Just take
the template provided by this gem as an example on how to write it.

Alternatively you can take a look at the jsfiddle demos from the Examples section.

# Plans for the future

There are so many but I'm not sure how long it will take to implement all of the intended
features in my spare time.

I'd like to support `given-and-when-and-then-and` style specs at some point.

But I wanted to have some initial working version published soon before someone register an
`oojspec` gem before me! :)

# Contributing

I'd love to hear your opinions on the API and design of `oojspec` and of course contributions
will be very welcome if they're aligned with this project goals.

Enjoy! :)
