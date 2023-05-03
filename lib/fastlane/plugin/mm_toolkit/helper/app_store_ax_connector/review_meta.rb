class ReviewMeta
    attr_reader :main, :other
    def initialize(paging)
        @paging = paging
        @total = paging['total']
        @limit = limit['limit']
    end

    def from_json(file)
        ReviewLink.new(file['paging'])
    end
end