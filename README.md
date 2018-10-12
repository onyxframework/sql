> ⚠️ Master branch requires Crystal master to compile. See [installation instructions for Crystal](https://crystal-lang.org/docs/installation/from_source_repository.html).

# Atom::Model

[![Built with Crystal](https://img.shields.io/badge/built%20with-crystal-000000.svg?style=flat-square)](https://crystal-lang.org/)
[![Build status](https://img.shields.io/travis/atomframework/model/master.svg?style=flat-square)](https://travis-ci.org/atomframework/model)
[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg?style=flat-square)](http://api.model.atomframework.org)
[![Releases](https://img.shields.io/github/release/atomframework/model.svg?style=flat-square)](https://github.com/atomframework/model/releases)
[![Awesome](https://github.com/vladfaust/awesome/blob/badge-flat-alternative/media/badge-flat-alternative.svg)](https://github.com/veelenga/awesome-crystal)

The official SQL ORM for [Atom Framework](https://github.com/atomframework/atom).

## Projects using Atom::Model

* [Crystal Jobs](https://crystaljobs.org)
* [Crystal World](https://github.com/vladfaust/crystalworld)
* *add yours!*

## About

Atom::Model is a [crystal-db](https://github.com/crystal-lang/crystal-db) ORM which does not follow Active Record pattern, it's more like a data-mapping solution. There is a concept of Repository, which is basically a gateway to the database. For example:

```crystal
repo = Atom::Repository.new(db)
users = repo.query(User.where(id: 42)).first
users.class # => User
```

Atom::Model also has a plently of features, including:

- Expressive and **type-safe** Query builder, allowing to use constructions like `Post.join(:author).where(author: user)`, which turns into a plain SQL
- References preloader (the example above would return a `Post` which has `#author = <User @id=42>` attribute set)
- Beautiful schema definition syntax

However, Atom::Model is designed to be minimal, so it doesn't perform tasks you may got used to, for example, it doesn't do database migrations itself. You may use [migrate](https://github.com/vladfaust/migrate.cr) instead. Also its Query builder is not intended to fully replace SQL but instead to help a developer to write less and safer code.

Also note that although Atom::Model code is designed to be abstract sutiable for any [crystal-db](https://github.com/crystal-lang/crystal-db) driver, it currently works with PostgreSQL only. But it's fairly easy to implement other drivers like MySQL or SQLite (see `/src/model/ext/pg` and `/src/model/repository.cr`).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  atom-model:
    github: atomframework/model
    version: ~> 0.5.0
```

This shard follows [Semantic Versioning v2.0.0](http://semver.org/), so check [releases](https://github.com/atomframework/model/releases) and change the `version` accordingly.

## Using

### Basic example

Assuming following database migration:

```sql
CREATE TABLE users(
  uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  age INT,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE posts(
  id SERIAL PRIMARY KEY,
  author_uuid INT NOT NULL REFERENCES users (uuid),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);
```

Crystal code:

```crystal
require "pg"
require "atom-model"

class User
  include Atom::Model

  schema users do
    pkey uuid : UUID # UUIDs are supported out of the box

    type name : String                   # Has NOT NULL in the column definition
    type age : Union(Int32 | Nil)        # Does not have NULL in the column definition
    type created_at : Time = DB::Default # Has DEFAULT in the column definition

    type posts : Array(Post), foreign_key: "author_uuid" # That is an implicit reference
  end
end

class Post
  include Atom::Model

  schema posts do
    pkey id : Int32

    type author : User, key: "author_id" # That is an explicit reference
    type content : String

    type created_at : Time = DB::Default
    type updated_at : Union(Time | Nil)
  end
end

logger = Atom::Repository::Logger::IO.new(STDOUT)
repo = Atom::Repository.new(DB.open(ENV["DATABASE_URL"]), logger)

# Most of the query builder methods (e.g. insert) are type-safe
user = repo.query(User.insert(name: "Vlad")).first

# You can use object-oriented approach as well
post = Post.new(author: user, content: "What a beauteful day!") # Oops

post = repo.query(post.insert).first
# Logging to STDOUT:
# [postgresql] INSERT INTO posts (author_uuid, content) VALUES (?, ?) RETURNING *
# 1.708ms
# [map] Post
# 126μs

# #to_s returns raw SQL string, so for superiour performance you may want to store it in constants
QUERY = Post.update.set(content: "placeholder").where(id: 0).to_s
# UPDATE posts SET content = ? WHERE (id = ?)

# However, such approach doesn't check for incoming params types, `post.id` could be anything
repo.exec(QUERY, "What a beautiful day!", post.id)

# Join with preloading references!
posts = repo.query(Post.where(author: user).join(:author, select: {"uuid", "name"}))

puts posts.first.inspect
# => <Post @id=42 @author=<User @name="Vlad" @uuid="..."> @content="What a beautiful day!">
```

### With [Atom](https://github.com/atomframework/atom)

Define your models just as above, but with [`Validations`](https://github.com/vladfaust/validations.cr) included by default. You also don't need to initialize repository explicitly when using Atom:

```crystal
require "pg"
require "atom"
require "atom/model"

class User
  include Atom::Model

  schema do
    type name : String
  end

  validate name, size: (3..50)
end

users = Atom.query(User.all) # Atom-level `query`, `exec` and `scalar` methods
User.new("Jo").valid?        # Validations
```

## Testing

1. Run generic specs with `crystal spec`
2. Apply migrations from `./db_spec/*/migration.sql`
3. Run DB-specific specs with `env POSTGRESQL_URL=postgres://postgres:postgres@localhost:5432/model crystal spec db_spec`
4. Optionally run benchmarks with `crystal bench.cr --release`

## Contributing

1. Fork it ( https://github.com/atomframework/model/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [@vladfaust](https://github.com/vladfaust) Vlad Faust - creator, maintainer
