# Generates CSV when given a collection and a mapping.
#
# Example:
#
#     columns = {
#       'Title' => 'title',
#       'Comment' => 'comment',
#       'Author' => -> (post) { post.author.full_name }
#       'Created At (UTC)' => -> (post) { post.created_at&.strftime('%Y-%m-%d %H:%M:%S') }
#     }
#
#     CsvBuilder.new(@posts, columns).render
#
class CsvBuilder
  #
  # * +collection+ - The data collection to be used
  # * +header_to_hash_value+ - A hash of 'Column Heading' => 'value_method'.
  #
  # The value method will be called once for each object in the collection, to
  # determine the value for that row. It can either be the name of a method on
  # the object, or a lamda to call passing in the object.
  def initialize(collection, header_to_value_hash)
    @header_to_value_hash = header_to_value_hash
    @collection = collection
    @truncated = false
  end

  # Renders the csv to a string
  def render(truncate_after_bytes = nil)
    tempfile = Tempfile.new('issues_csv')
    csv = CSV.new(tempfile)

    write_csv(csv) do
      truncate_after_bytes && tempfile.size > truncate_after_bytes
    end

    tempfile.rewind
    tempfile.read
  ensure
    tempfile.close
    tempfile.unlink
  end

  def truncated?
    @truncated
  end

  private

  def headers
    @headers ||= @header_to_value_hash.keys
  end

  def attributes
    @attributes ||= @header_to_value_hash.values
  end

  def row(object)
    attributes.map do |attribute|
      if attribute.respond_to?(:call)
        attribute.call(object)
      else
        object.send(attribute)
      end
    end
  end

  def write_csv(csv, &until_block)
    csv << headers

    @collection.find_each do |object|
      csv << row(object)

      if until_block.call
        @truncated = true
        break
      end
    end
  end
end
