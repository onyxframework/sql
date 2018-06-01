require "./instance/*"

module Core::Query
  struct Instance(Schema)
    # A list of params for this query.
    getter params = [] of Param
    protected setter params

    enum QueryType
      Select
      Update
      Delete
    end

    getter query_type = QueryType::Select
    protected setter query_type

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
      clone.query_type = self.query_type
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

    # Mark this query as a SELECT one (default)
    def select
      @query_type = QueryType::Select
      self
    end

    # Mark this query as an UPDATE one
    def update
      @query_type = QueryType::Update
      self
    end

    # Mark this query as a DELETE one
    def delete
      @query_type = QueryType::Delete
      self
    end

    # Remove this query's `#limit` and return itself.
    #
    # ```
    # query = Instance(User).new.limit(3).offset(5).all.to_s
    # # => SELECT * FROM users OFFSET 5
    # ```
    def all
      limit(nil)
      self
    end

    # Sets this query limit to 1.
    #
    # ```
    # query = Instance(User).new.one.to_s
    # # => SELECT * FROM users LIMIT 1
    # ```
    def one
      limit(1)
      self
    end

    # Query the last row by `Model::Schema.primary_key[:name]`.
    #
    # ```
    # Instance(User).new.last.to_s
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
    # Instance(User).new.first.to_s
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

      case query_type
      when QueryType::Select
        append_select_clauses
        query += " FROM " + Schema.table
      when QueryType::Update
        query += "UPDATE " + Schema.table
        append_set_clauses
      when QueryType::Delete
        query += "DELETE FROM " + Schema.table
      end

      append_join_clauses
      append_where_clauses
      append_group_by_clauses
      append_having_clauses
      append_order_by_clauses
      append_limit_clause
      append_offset_clause

      query.strip
    end
  end
end
