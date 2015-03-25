require 'cgi'
require 'opendmm/movie'
require 'opendmm/search'
require 'opendmm/utils/httparty'

module OpenDMM
  module Engine
    module TokyoHot
      def self.search(query)
        case query
        when /Tokyo Hot n(\d{3,4})/i
          query = "n#{$1.rjust(4, '0')}"
          MovieN.new(query).details
        when /Tokyo Hot k(\d{3,4})/i
          query = "k#{$1.rjust(4, '0')}"
          MovieK.new(query).details
        else
          nil
        end
      end

      private

      module Site
        include HTTParty
        base_uri 'www.tokyo-hot.com'

        def self.list_n
          get "/j/new_video0000_j.html"
        end

        def self.list_k
          get "/j/k_video0000_j.html"
        end
      end

      class MovieN < OpenDMM::Movie
        def initialize(query)
          super(query, Site.list_n)
          @details.code         = "Tokyo Hot #{query}"
          @details.maker        = 'Tokyo Hot'

          link = @html.at_xpath("//a[contains(@href, '#{@query}')]")
          @details.page         = link['href']
          @details.cover_image  = link.at_css('img')['src']

          table = link.ancestors('table').first
          table.css('br').each do |br|
            br.replace "\n"
          end
          @details.title        = table.at_xpath('tr[1]').text
          @details.actresses    = table.at_xpath('tr[2]').text.squish.remove('--').split(/[\s、,]/)
          @details.release_date = table.at_xpath('tr[3]').text.remove('更新日')
        end
      end

      class MovieK < OpenDMM::Movie
        def initialize(query)
          super(query, Site.list_k)
          @details.code         = "Tokyo Hot #{query}"
          @details.maker        = 'Tokyo Hot'

          link = @html.at_xpath("//a[contains(@href, '#{@query}')]")
          @details.page         = link['href']
          @details.cover_image  = link.at_css('img')['src']

          table = link.ancestors('table').first
          @details.title        = table.at_xpath('tr[1]').text.remove('-').squish
          if @details.title =~ /餌食牝\s(.*)/
            @details.actresses = $1.squish.split
            @details.title = '餌食牝'
          end
          @details.release_date = table.at_xpath('tr[2]').text.remove('更新日')
        end
      end
    end
  end
end