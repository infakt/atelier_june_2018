module Api
  module V1
    class BooksController < ::Api::V1::BaseController
      
      def lookup
        render json: books
      end

      private

      def books
        Book.includes(:category).map do |book|
          book.attributes.slice('title', 'isbn')
            .merge(category_name: book.category_name)
            .symbolize_keys
        end
      end
    end
  end
end
