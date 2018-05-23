require "../../schema_spec"
require "../../../src/core/converters/enum"
require "../../../src/core/converters/pg/numeric"

module Schema::FieldsSpec
  class User
    include Core::Schema

    enum Role
      User
      Admin
    end

    schema :users do
      primary_key :id
      field :role, Role, converter: Core::Converters::Enum(Role)
      field :active, Bool, db_default: true
      field :foo, String, key: :foo_column, default: "Foo"
      field :bar, Float64?, converter: Core::Converters::PG::Numeric
      field :created_at, Time
      field :updated_at, Time, nilable: true
    end
  end

  describe "Schema#field" do
    it "gen .primary_key_field" do
      User.primary_key[:name].should eq :id
    end

    it "gen .primary_key_type" do
      User.primary_key[:type].should eq Core::PrimaryKey
    end

    user = User.new(id: 42, bar: 0.to_f64.as(Float64?))

    it "gen #fields" do
      user.fields.should eq ({
        :id         => 42,
        :role       => nil,
        :active     => nil,
        :foo        => "Foo",
        :bar        => 0.to_f64,
        :created_at => nil,
        :updated_at => nil,
      })
    end

    it "gen #primary_key_value" do
      user.primary_key.should eq 42
    end

    it "gen properties" do
      user.id.should eq 42

      user.active?.should be_nil

      expect_raises Exception do
        user.role
      end
      user.role?.should be_nil

      user.foo.should eq "Foo"
      user.bar.class.should eq Float64

      expect_raises Exception do
        user.created_at
      end
      user.created_at?.should be_nil

      user.updated_at.should be_nil
    end
  end
end
