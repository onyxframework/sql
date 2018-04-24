require "./instance/*"

module Core::Query
  struct Instance(Schema)
    # A list of params for this query.
    getter params = [] of ::DB::Any
    protected setter params

    # Reset all the values to defaults.
    #
    # TODO: Split to modules. Currently impossible due to https://github.com/crystal-lang/crystal/issues/5023
    def reset
      params.clear
      group_by_clauses.clear
      having_clauses.clear
      join_clauses.clear
      @limit_clause = nil
      @offset_clause = nil
      order_by_clauses.clear
      select_clauses.clear
      where_clauses.clear
      self
    end

    # TODO: Split to modules. Currently impossible due to https://github.com/crystal-lang/crystal/issues/5023
    def clone
      clone = self.class.new
      clone.group_by_clauses = self.group_by_clauses.dup
      clone.having_clauses = self.having_clauses.clone
      clone.join_clauses = self.join_clauses.clone
      clone.limit_clause = self.limit_clause
      clone.offset_clause = self.offset_clause
      clone.order_by_clauses = self.order_by_clauses.dup
      clone.select_clauses = self.select_clauses.dup
      clone.where_clauses = self.where_clauses.clone
      return clone
    end

    # Remove this query's `#limit` and return itself.
    #
    # ```
    # query = Query(User).new.limit(3).offset(5).all.to_s
    # # => SELECT * FROM users OFFSET 5
    # ```
    def all
      limit(nil)
      self
    end

    # Sets this query limit to 1.
    #
    # ```
    # query = Query(User).new.one.to_s
    # # => SELECT * FROM users LIMIT 1
    # ```
    def one
      limit(1)
      self
    end

    # Query the last row by `Model::Schema.primary_key[:name]`.
    #
    # ```
    # Query(User).new.last.to_s
    # # => SELECT * FROM users ORDER BY id DESC LIMIT 1
    # ```
    def last
      order_by(Schema.primary_key[:name], :DESC)
      one
      self
    end

    # Query the first row by `Model::Schema.primary_key[:name]`.
    #
    # ```
    # Query(User).new.first.to_s
    # # => SELECT * FROM users ORDER BY id ASC LIMIT 1
    # ```
    def first
      order_by(Schema.primary_key[:name], :ASC)
      one
      self
    end

    # Build the query, returning its SQL representation.
    #
    # NOTE: `#params` are empty until built.
    def to_s
      params.clear
      query = ""

      append_select_clauses
      append_from_clause
      append_join_clauses
      append_where_clauses
      append_group_by_clauses
      append_having_clauses
      append_order_by_clauses
      append_limit_clause
      append_offset_clause

      query.strip
    end

    # :nodoc:
    macro append_from_clause
      query += " FROM " + Schema.table
    end
  end
end
