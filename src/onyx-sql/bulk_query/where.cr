module Onyx::SQL
  class BulkQuery(T)
    protected def append_where(sql, params, params_index)
      {% begin %}
        {%
          options = T.annotation(Model::Options)
          raise "Onyx::SQL::Model::Options annotation must be defined for #{T}" unless options

          pk = options[:primary_key]
          raise "Onyx::SQL::Model::Options annotation is missing :primary_key option for #{T}" unless pk

          pk_ivar = T.instance_vars.find { |iv| "@#{iv.name}".id == pk.id }
          raise "Cannot find primary key field #{pk} for #{T}" unless pk_ivar
        %}

        sql << " WHERE " << T.db_column({{pk_ivar.name.symbolize}})
        sql << " IN (" << @instances.join(", ") do
          params_index ? "$#{params_index.value += 1}" : '?'
        end << ')'

        if params
          params.concat(@instances.map do |i|
            T.db_values({{pk_ivar.name}}: i.{{pk_ivar.name}}!)[0]
          end)
        end
      {% end %}
    end
  end
end
