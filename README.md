<a href="https://onyxframework.org"><img width="100" height="100" src="https://onyxframework.org/img/logo.svg"></a>

# Onyx::SQL

[![Built with Crystal](https://img.shields.io/badge/built%20with-crystal-000000.svg?style=flat-square)](https://crystal-lang.org/)
[![Travis CI build](https://img.shields.io/travis/onyxframework/sql/master.svg?style=flat-square)](https://travis-ci.org/onyxframework/sql)
[![Docs](https://img.shields.io/badge/docs-online-brightgreen.svg?style=flat-square)](https://docs.onyxframework.org/sql)
[![API docs](https://img.shields.io/badge/api_docs-online-brightgreen.svg?style=flat-square)](https://api.onyxframework.org/sql)
[![Latest release](https://img.shields.io/github/release/onyxframework/sql.svg?style=flat-square)](https://github.com/onyxframework/sql/releases)

A deligtful SQL ORM.

## About 👋

Onyx::SQL is a deligthful database-agnostic SQL ORM for [Crystal language](https://crystal-lang.org/). It features a convenient schema definition DSL, type-safe SQL query builder, clean architecture with Repository and more!

## Installation 📥

Add these lines to your application's `shard.yml`:

```yaml
dependencies:
  onyx:
    github: onyxframework/onyx
    version: ~> 0.4.0
  onyx-sql:
    github: onyxframework/sql
    version: ~> 0.8.0
```

This shard follows [Semantic Versioning v2.0.0](http://semver.org/), so check [releases](https://github.com/onyxframework/rest/releases) and change the `version` accordingly.

> Note that until Crystal is officially released, this shard would be in beta state (`0.*.*`), with every **minor** release considered breaking. For example, `0.1.0` → `0.2.0` is breaking and `0.1.0` → `0.1.1` is not.

You'd also need to add a database dependency conforming to the [crystal-db](https://github.com/crystal-lang/crystal-db) interface. For example, [pg](https://github.com/will/crystal-pg):

```diff
dependencies:
  onyx:
    github: onyxframework/onyx
    version: ~> 0.4.0
  onyx-sql:
    github: onyxframework/sql
    version: ~> 0.8.0
+ pg:
+   github: will/crystal-pg
+   version: ~> 0.18.0
```

## Usage 💻

For this PostgreSQL table:

```sql
CREATE TABLE users (
  id          SERIAL      PRIMARY KEY,
  name        TEXT        NOT NULL
  created_at  TIMESTAMPTZ NOT NULL  DEFAULT now()
);
```

Define the user schema:

```crystal
require "onyx/sql"

class User
  include Onyx::SQL::Model

  schema users do
    pkey id : Int32
    type name : String, not_null: true
    type created_at : Time, not_null: true, default: true
  end
end
```

Insert a new user instance:

```crystal
user = User.new(name: "John")
user = Onyx::SQL.query(user.insert.returning("*")).first

pp user # => #<User @id=1, @name="John", @created_at=#<Time ...>>
```

Query the user:

```crystal
user = Onyx::SQL.query(User.where(id: 1)).first?
```

With another PostgreSQL table:

```sql
CREATE TABLE posts (
  id          SERIAL      PRIMARY KEY,
  author_id   INT         NOT NULL  REFERENCES  users(id),
  content     TEXT        NOT NULL
  created_at  TIMESTAMPTZ NOT NULL  DEFAULT now()
);
```

Define the post schema:

```crystal
class Post
  include Onyx::SQL::Model

  schema posts do
    pkey id : Int32
    type author : User, not_null: true, key: "author_id"
    type content : String, not_null: true
    type created_at : Time, not_null: true, default: true
  end
end
```

Add the posts reference to the user schema:

```diff
class User
  include Onyx::SQL::Model

  schema users do
    pkey id : Int32
    type name : String, not_null: true
    type created_at : Time, not_null: true, default: true
+   type authored_posts : Array(Post), foreign_key: "author_id"
  end
end
```

Create a new post:

```crystal
user = User.new(id: 1)
post = Post.new(author: user, content: "Hello, world!")
Onyx::SQL.exec(post.insert)
```

Query all the posts by a user with name "John":

```crystal
posts = Onyx::SQL.query(Post
  .join(author: true) do |x|
    x.select(:id, :name)
    x.where(name: "John")
  end
)

posts.first # => #<Post @id=1, @author=#<User @id=1 @name="John">, @content="Hello, world!">
```

## Documentation 📚

The documentation is available online at [docs.onyxframework.org/sql](https://docs.onyxframework.org/sql).

## Community 🍪

There are multiple places to talk about Onyx:

* [Gitter](https://gitter.im/onyxframework)
* [Twitter](https://twitter.com/onyxframework)

## Support 🕊

This shard is maintained by me, [Vlad Faust](https://vladfaust.com), a passionate developer with years of programming and product experience. I love creating Open-Source and I want to be able to work full-time on Open-Source projects.

I will do my best to answer your questions in the free communication channels above, but if you want prioritized support, then please consider becoming my patron. Your issues will be labeled with your patronage status, and if you have a sponsor tier, then you and your team be able to communicate with me privately in [Twist](https://twist.com). There are other perks to consider, so please, don't hesistate to check my Patreon page:

<a href="https://www.patreon.com/vladfaust"><img height="50" src="https://onyxframework.org/img/patreon-button.svg"></a>

You could also help me a lot if you leave a star to this GitHub repository and spread the word about Crystal and Onyx! 📣

## Contributing

1. Fork it ( https://github.com/onyxframework/sql/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'feat: some feature') using [Angular style commits](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#commit)
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Vlad Faust](https://github.com/vladfaust) - creator and maintainer

## Licensing

This software is licensed under [MIT License](LICENSE).

[![Open Source Initiative](https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Opensource.svg/100px-Opensource.svg.png)](https://opensource.org/licenses/MIT)
