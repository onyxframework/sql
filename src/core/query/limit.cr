module Core
  struct Query(T)
    @limit : Int32 | Nil = nil
    protected property limit

    # Add `LIMIT` clause. Unset with `nil`.
    def limit(@limit : Int32 | Nil = nil)
      self
    end

    private macro append_limit(query)
      if @limit
        {{query}} += " LIMIT ?"
        ensure_params.push(@limit.as(DB::Any))
      end
    end
  end
end
