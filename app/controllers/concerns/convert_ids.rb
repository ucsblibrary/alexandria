module ConvertIds
  extend ActiveSupport::Concern
  private

    def convert_ark_to_id
      if id = Identifier.ark_to_id(params[:id])
        params[:id] = id
      elsif id = Identifier.treeify(params[:id])
        params[:id] = id
      end
    end

end
