class MergeRecordsJob < ActiveJob::Base
  queue_as :merge

  def perform(record_id, merge_target_id, _user_id = nil)
    record = ActiveFedora::Base.find(record_id)
    merge_target = ActiveFedora::Base.find(merge_target_id)
    MergeRecordsService.new(record, merge_target).run
  end
end
