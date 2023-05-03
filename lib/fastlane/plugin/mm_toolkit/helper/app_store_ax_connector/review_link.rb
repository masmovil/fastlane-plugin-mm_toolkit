class ReviewLink
    attr_reader :main, :other
    def initialize(main, other)
        @main = main
        @other = other
    end

    def from_json(file)
        ReviewLink.new(file['self'], file['next'])
    end
end