require "../../model_spec"
require "../../../src/core/converters/enum"
require "../../../src/core/converters/pg/numeric"

module Model::Schema::FieldsSpec
  class User < Core::Model
    enum Role
      User
      Admin
    end

    schema :users do
      primary_key :id
      field :role, Role, converter: Core::Converters::Enum(Role)
      field :foo, String, key: :foo_column, default: "Foo"
      field :bar, Float64?, converter: Core::Converters::PG::Numeric
      field :created_at, Time, created_at_field: true
      field :updated_at, Time, nilable: true, updated_at_field: true
    end
  end

  describe ".field" do
    it "gen class getter .primary_key_field" do
      User.primary_key[:name].should eq :id
    end

    it "gen class getter .primary_key_type" do
      User.primary_key[:type].should eq Core::PrimaryKey
    end

    user = User.new(id: 42, bar: 0.to_f64.as(Float64?))

    it "gen instance getter #fields" do
      user.fields.should eq ({
        :id         => 42,
        :role       => nil,
        :foo        => "Foo",
        :bar        => 0.to_f64,
        :created_at => nil,
        :updated_at => nil,
      })
    end

    it "gen instance getter #primary_key_value" do
      user.primary_key.should eq 42
    end

    it "gen properties" do
      user.id.should eq 42

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
