require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject


  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns.first.map { |str| str.to_sym }
  end

  def self.finalize!
    columns.each do |name|
      define_method("#{name}=") do |value|
        attributes[name] = value
      end

      define_method(name) do
        attributes[name]
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    results = parse_all(results).first
  end

  def initialize(params = {})
    # class_name = "#{self.class}".capitalize
    # p self.class
    class_columns = self.class.columns
    # p class_columns
    params.each do |name, value|
      if class_columns.include?(name.to_sym)
        send("#{name}=", value)
      else
        raise "unknown attribute '#{name}'"
      end
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |name| send(name)}
  end

  def insert
    col_names = self.class.columns.drop(1) # drop id
    col_names2 = col_names.map(&:to_s).join(", ")
    question_marks = (["?"] * col_names.length).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name} (#{col_names2})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns
      .map { |attr| "#{attr} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
    # col_names = self.class.columns# drop id
    # col_names2 = col_names.map(&:to_s).join(" = ?, ") + " = ?"
    # p col_names2
    # p *attribute_values
    # DBConnection.execute(<<-SQL, *attribute_values, self.id)
    # UPDATE
    #   #{self.class.table_name}
    # VALUES
    #   (#{col_names2})
    # WHERE
    #   id = ?
    # SQL
    # self.id = DBConnection.last_insert_row_id
  end

  def save
    id.nil? ? insert : update
  end
end





















##
