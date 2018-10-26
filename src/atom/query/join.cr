class Atom
  struct Query(T)
    # Supported join types.
    enum JoinType
      Inner
      Left
      Right
      Full

      def to_s
        super.upcase
      end
    end

    private struct Join
      getter :type, table, :alias, on

      def initialize(
        @type : JoinType,
        @table : String,
        @alias : String | Nil,
        @on : String
      )
      end
    end

    @join : Array(Join) | Nil = nil
    protected property join

    # Add `JOIN` clause by *table* *on*.
    #
    # ```
    # Post.join("users", "author.id = posts.author_id", as: "author")
    # # SELECT FROM posts JOIN users ON author.id = posts.author_id AS author
    # ```
    def join(
      table : String,
      on : String,
      *,
      type _type : JoinType = :inner,
      as _as : String | Nil = nil
    )
      @join = Array(Join).new if @join.nil?
      @join.not_nil! << Join.new(type: _type, table: table, alias: _as, on: on)
      self
    end

    # Add `JOIN` clause by *reference*.
    #
    # ```
    # class User
    #   schema users do
    #     pkey id : Int32
    #     type posts : Array(Post), foreign_key: "author_id"
    #   end
    # end
    #
    # class Post
    #   schema posts do
    #     pkey id : Int32
    #     type author : User, key: "author_id"
    #     type content : String
    #   end
    # end
    #
    # Post.join(:author)
    # # SELECT posts.* FROM posts JOIN users ON posts.author_id = author.id AS author
    #
    # User.join(:posts, select: {Post.id, Post.content})
    # # SELECT users.*, '' AS _posts, posts.id, posts.content FROM users JOIN posts ON posts.author_id = users.id
    # ```
    #
    # If `#select` hasn't been called before, a `#select(T)` call is made to ensure the model itself is selected along with the joined reference.
    #
    # Note that if you call `#select` with any of curent model columns **after** `#join` for the first time, it will lead to repeated columns and therefore to `DB::MappingException`:
    #
    # ```
    # Post.join(:author, select: {"id"}).select(:id)
    # # SELECT posts.*, '' AS author, author.id, posts.id ...
    # #                                                ^ error
    #
    # Post.select(:id).join(:author, select: {"id"})
    # # SELECT posts.id, '' AS author, author.id
    # # OK                                        ^ error
    #
    # Post.select(:id).join(:author, select: {"id"}).select(:content)
    # # SELECT posts.id, '' AS author, author.id, posts.content
    # # OK, but may lead to confusion if author has "content" column
    # ```
    #
    # NOTE: Direct enumerable reference joins are forbidden at the moment, e.g. you can't join `:tags` with `type tags : Array(Tag), key: "tag_ids"`.
    #
    # NOTE: *select*s are modified like `"{as}.{select}"`.
    #
    # TODO: Allow to `select:` by *reference* `Attrubute`, e.g. `select: {:content}`.
    def join(
      reference : T::Reference,
      *,
      type _type : JoinType = :inner,
      as _as : String = reference.to_s.underscore,
      select _select : Char | String | Enumerable(String | Char) | Nil = nil
    )
      on = if reference.direct?
             "#{T.table}.#{reference.key} = \"#{_as}\".#{reference.primary_key}"
           else
             "\"#{_as}\".#{reference.foreign_key} = #{T.table}.#{T.primary_key.key}"
           end

      if _select
        # Add `SELECT table.*` if not set before, so the model is selected along with the reference
        self.select(T) if self.select.empty?

        # Add reference marker (see `/src/schema/db_mapping.cr`)
        self.select("'' AS _#{reference.to_s.underscore}")

        if _select.is_a?(Enumerable)
          _select.each do |s|
            self.select(_as ? "\"#{_as}\"" + '.' + s : s)
          end
        else
          self.select(_as ? "\"#{_as}\"" + '.' + _select : _select)
        end
      end

      join(reference.table, on, type: _type, as: _as)
    end

    {% for t in %i(left right full) %}
      # Alias of `#join(table, on, type: {{t}})`.
      def {{t.id}}_join(table : String, on : String,)
        join(table, on, type: {{t}})
      end

      # Alias of `#join(reference, type: {{t}})`.
      def {{t.id}}_join(reference : T::Reference, **nargs)
        join(reference, **nargs, type: {{t}})
      end
    {% end %}

    private macro append_join(query)
      unless @join.nil?
        {{query}} += @join.not_nil!.join(" ") do |join|
          j = " #{join.type} JOIN #{join.table}"
          j += (" AS \"#{join.alias}\"") if join.alias && join.table != join.alias
          j += " ON #{join.on}"
        end
      end
    end
  end
end
