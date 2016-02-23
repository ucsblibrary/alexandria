class CurationConcerns::FileSetsController < ApplicationController
  include CurationConcerns::FileSetsControllerBehavior
  # def presenter
  #   byebug
  #   super
  # end
  def search_builder_class
    ::FileSetSearchBuilder
  end
end
