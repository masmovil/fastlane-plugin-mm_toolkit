## Development documentation

### Ruby versions
The project bundles a [`.ruby-version`](../.ruby-version) file that specifies the Ruby version that the project uses.

You can use tools like [RVM](https://rvm.io/) or [rbenv](https://github.com/rbenv/rbenv) to enforce this specific version when working on this project.

#### Installing `RVM`
* [Check the docs](https://rvm.io/rvm/install) to install it in your system.
* It is recommended to install some sort of shell extension to automatically load RVM if a `.ruby-version` file is found in the working directory:
  * `bash`: check [this documentation](https://rvm.io/integration/gnome-terminal)
  * `zsh`: if you use `oh-my-zsh`, the [rvm plug-in](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/rvm) will handle load of rvm environments automaticallu after adding the plugin to your `.zshrc`
* If you don't have automatic load, you'll need to call `rvm use` whenever you want to interact with Ruby stuff so it picks the requested version in `.ruby-version`
* RVM may prompt you to install the required Ruby version in your system, so just do `rvm install $(cat .ruby-version)` in the root of the project.

#### Installing `rbenv`
* To whoever read this and wants to install it, please fill this section 👀

### Ruby linter: `Rubocop`
[Rubocop](https://github.com/rubocop-hq/rubocop) is a Ruby static code analyzer (a.k.a. linter) and code formatter. Out of the box it will enforce many of the guidelines outlined in the community Ruby Style Guide. Apart from reporting the problems discovered in your code, RuboCop can also automatically fix many of them for you.

We use [Shopify's Rubocop style guide](https://shopify.github.io/ruby-style-guide/) with some tweaks that you can see in [`.rubocop.yml`](../.rubocop.yml).

If you want to run the linter, do:
```sh
bundle exec rubocop -a
```
which should also fix most errors automatically.

### Ruby command line: `pry`
[pry](https://github.com/pry/pry) is a runtime developer console and IRB alternative with powerful introspection capabilities.
You can use this tool as a replacement of `irb` that is also aware of the currently installed gems.

If you want to use it, do:
```sh
bundle exec pry
```