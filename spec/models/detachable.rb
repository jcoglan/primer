class Detachable
  include Primer::Worker
  
  def concat(*args)
    $concat_result = args * ', '
  end
  dispatch_to_worker :concat, :queue => 'concat'
  
  def primer_identifier
    []
  end
end
