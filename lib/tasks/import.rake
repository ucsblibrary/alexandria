# frozen_string_literal: true

namespace :import do
  desc "Import merritt arks from csv for UCSB ETDs"

  task merritt_arks: :environment do
    # CSV file contents as below
    # Proquest ID,Meritt Ark,UCSB Ark
    # ProQuestID:10951,ark:/13030/m30865g5,ark:/48907/f30865g5
    Rails.logger.info "Complete"
  end
end
