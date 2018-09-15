require "./bench_helper"

puts "\nRunning Query benchmarks...".colorize(COLORS["header"])

elapsed = Time.measure do
  {% for building in [false, true] %}
    puts "\n> with#{{{building ? "" : "out"}}} building\n".colorize(COLORS["subheader"])

    Benchmark.ips do |x|
      x.report("empty") do
        User.query{{".to_s".id if building}}
      end

      x.report("#group_by") do
        User.group_by("foo"){{".to_s".id if building}}
      end

      x.report("#having w/o args") do
        User.having("foo"){{".to_s".id if building}}
      end

      x.report("#having w/  single arg") do
        User.having("foo", 42){{".to_s".id if building}}
      end

      x.report("#having w/  two args") do
        User.having("foo", 42, [43, 44]){{".to_s".id if building}}
      end

      x.report("#insert w/  single attr. arg") do
        User.insert(name: "John"){{".to_s".id if building}}
      end

      x.report("#insert w/  two attr. args") do
        User.insert(name: "John", active: true){{".to_s".id if building}}
      end

      ref = User.new(uuid: UUID.random)

      x.report("#insert w/  two + ref. arg") do
        User.insert(name: "John", referrer: ref){{".to_s".id if building}}
      end

      x.report("#join w/  table") do
        Post.join("users", "post.author_id = author.id", as: "author"){{".to_s".id if building}}
      end

      x.report("#join w/  reference") do
        Post.join(:author, select: {'*'}){{".to_s".id if building}}
      end

      x.report("#limit") do
        User.limit(1){{".to_s".id if building}}
      end

      x.report("#offset") do
        User.offset(1){{".to_s".id if building}}
      end

      x.report("#order_by w/  string arg") do
        User.order_by("foo", :desc){{".to_s".id if building}}
      end

      x.report("#order_by w/  attr. arg") do
        User.order_by(:uuid, :desc){{".to_s".id if building}}
      end

      x.report("#returning w/  single string arg") do
        User.returning("*"){{".to_s".id if building}}
      end

      x.report("#returning w/  single char arg") do
        User.returning('*'){{".to_s".id if building}}
      end

      x.report("#returning w/  single attr. arg") do
        User.returning(:uuid){{".to_s".id if building}}
      end

      x.report("#returning w/  two args") do
        User.returning(:uuid, "foo"){{".to_s".id if building}}
      end

      x.report("#select w/  single char arg") do
        User.select('*'){{".to_s".id if building}}
      end

      x.report("#select w/  single string arg") do
        User.select("*"){{".to_s".id if building}}
      end

      x.report("#select w/  single attr. arg") do
        User.select(:uuid){{".to_s".id if building}}
      end

      x.report("#select w/  two args") do
        User.select(:uuid, "foo"){{".to_s".id if building}}
      end

      x.report("#set w/  single attr. arg") do
        User.set(name: "John"){{".to_s".id if building}}
      end

      x.report("#set w/  two attr. args") do
        User.set(name: "John", active: true){{".to_s".id if building}}
      end

      x.report("#set w/  single ref. arg") do
        User.set(referrer: ref){{".to_s".id if building}}
      end

      x.report("#where w/  single attr. arg") do
        User.where(name: "John"){{".to_s".id if building}}
      end

      x.report("#where w/  two attr. args") do
        User.where(name: "John", active: true){{".to_s".id if building}}
      end

      x.report("#where w/  single ref. arg") do
        User.where(referrer: ref){{".to_s".id if building}}
      end
    end
  {% end %}
end

puts "\nCompleted in #{TimeFormat.auto(elapsed)} ✔️".colorize(COLORS["success"])
