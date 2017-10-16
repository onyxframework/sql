# Core

**C**rystal **O**bject **RE**lational Mapping you've been waiting for.

[![Build Status](https://travis-ci.org/vladfaust/core.cr.svg?branch=master)](https://travis-ci.org/vladfaust/core.cr) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://vladfaust.com/core.cr) [![Dependency Status](https://shards.rocks/badge/github/vladfaust/core.cr/status.svg)](https://shards.rocks/github/vladfaust/core.cr) [![GitHub release](https://img.shields.io/github/release/vladfaust/core.cr.svg)](https://github.com/vladfaust/core.cr/releases)

## About

Tired of [ActiveRecord](https://wikipedia.org/wiki/Active_record_pattern)'s magic? Forget it. It's time for real programming!

**Core** is inspired by [Crecto](https://github.com/Crecto/crecto) but more transparent and Crystal-ish.

### Features:

  - Use plain Crystal `Core::Model`s without ActiveRecord's magic methods;
  - Interact with Database via `Core::Repository`;
  - Build powerful queries with `Core::Query`;
  - Enjoy comprehensive [documenation](https://vladfaust.com/core.cr)!

### What Core does not:

  - It doesn't do database migrations. Use [micrate](https://github.com/juanedi/micrate), for example;
  - It doesn't have _"handy"_ methods you probably got used to.
  Need to count something? Use plain [db#scalar](http://crystal-lang.github.io/crystal-db/api/latest/DB/QueryMethods.html#scalar). `Core::Repository` is for [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete), not for endless utils.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  core:
    github: vladfaust/core.cr
```

## Usage

Assuming following initial database migration:

```sql
CREATE TABLE users(
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL,
  created_at  TIMESTAMPTZ   NOT NULL,
  updated_at  TIMESTAMPTZ
);

CREATE TABLE posts(
  id          SERIAL PRIMARY KEY,
  author_id   INT         NOT NULL  REFERENCES users (id),
  content     TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL,
  updated_at  TIMESTAMPTZ
);
```

```crystal
require "core"
require "db"
require "pg" # Or another driver

class User < Core::Model
  schema do
    primary_key :id
    field :name, String
    virtual_field :posts_count, Int64
    reference :posts, Array(Post), foreign_key: :author_id
    created_at_field :created_at
    updated_at_field :updated_at
  end

  validation do
    errors.push({:name => "length must be >= 3"}) unless name.try &.size.>= 3
  end
end

class Post < Core::Model
  schema do
    primary_key :id
    field :content, String
    reference :author, User, key: :author_id
    created_at_field :created_at
    updated_at_field :updated_at
  end
end

db = DB.open(ENV["DATABASE_URL"])
query_logger = Core::QueryLogger.new(STDOUT)
repo = Core::Repository.new(db, query_logger)

user = User.new(name: "Fo")
user.valid? # => false
user.errors # => [{:name => "length must be >= 3"}]
user.name = "Foo"
user.valid? # => true

user.id = repo.insert(user) # See ^1
# INSERT INTO users (name, created_at) VALUES ($1, $2) RETURNING id

post = Post.new(author: user, content: "Foo Bar")
post.id = repo.insert(post) # See ^1
# INSERT INTO posts (author_id, content, created_at) VALUES ($1, $2, $3) RETURNING id

alias Query = Core::Query

posts = repo.query(Query(Post).where(author: user))
# SELECT * FROM posts WHERE author_id = $1

posts.first.content # => "Foo Bar"

query = Query(User)
  .join(:posts)
  .select(:*, :"COUNT(posts.id) AS posts_count")
  .group_by(%i(users.id posts.id))
  .one
user = repo.query(query).first
# SELECT *, COUNT (posts.id) AS posts_count
# FROM users JOIN posts AS posts ON posts.author_id = users.id
# GROUP BY users.id, posts.id LIMIT 1

user.posts_count # => 1

user.name = "Bar"
user.changes # => {:name => "Bar"}
repo.update(user)
# UPDATE users SET name = $1 WHERE id = $2 RETURNING id

repo.delete(posts.first)
# DELETE FROM posts WHERE id = $1
```

**^1:** Returning IDs is not working for PostgreSQL yet. See https://github.com/will/crystal-pg/issues/112.

## Testing

1. Apply migration from `./spec/migration.sql`
2. Run `env DATABASE_URL=your_database_url crystal spec`

## Contributing

1. Fork it ( https://github.com/vladfaust/core.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [@vladfaust](https://github.com/vladfaust) Vlad Faust - creator, maintainer
