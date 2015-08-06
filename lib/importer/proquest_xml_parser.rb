# Parse an XML metadata file from the ProQuest system, and
# collect all the interesting values in the attributes hash.

module Importer
  class ProquestXmlParser

    def initialize(file_contents)
      @doc = Nokogiri::XML(file_contents)
    end

    def attributes
      embargo_attributes.merge(
        keywords: keywords,
        rights_holder: rights_holder,
        date_copyrighted: date_copyrighted)
    end

    private

      def rights_holder
        path = @doc.xpath('//DISS_author[@type="primary"]/DISS_name')
        [path.xpath('DISS_fname').text, path.xpath('DISS_surname').text].join(' ')
      end

      def date_copyrighted
        sdate = @doc.xpath('//DISS_dates/DISS_accept_date').text
        Date.parse(sdate).year unless sdate.blank?
      end

      def keywords
        @doc.xpath('//DISS_keyword').text.split(/,\s+/)
      end

      def embargo_attributes
        embargo_xpaths.inject({}) do |attrs, (field, xpath)|
          element = @doc.xpath(xpath)
          value = element.text
          value = nil if value.blank?
          attrs.merge(field => value)
        end
      end

      def embargo_xpaths
        { embargo_code: 'DISS_submission/@embargo_code',
          DISS_accept_date: '//DISS_accept_date',
          DISS_agreement_decision_date: '//DISS_agreement_decision_date',
          DISS_delayed_release: '//DISS_delayed_release',
          DISS_access_option: '//DISS_access_option',
          embargo_remove_date: '//DISS_sales_restriction/@remove'
        }
      end
  end
end
